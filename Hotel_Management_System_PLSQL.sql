-- Step 1: Create required tables

-- Table for storing room details
CREATE TABLE rooms (
    room_id NUMBER PRIMARY KEY,
    room_type VARCHAR2(50),
    is_available CHAR(1) CHECK (is_available IN ('Y', 'N'))
);

-- Table for storing guest details
CREATE TABLE guests (
    guest_id NUMBER PRIMARY KEY,
    guest_name VARCHAR2(100),
    contact_number VARCHAR2(15)
);

-- Table for storing booking details
CREATE TABLE bookings (
    booking_id NUMBER PRIMARY KEY,
    guest_id NUMBER REFERENCES guests(guest_id),
    room_id NUMBER REFERENCES rooms(room_id),
    check_in_date DATE,
    check_out_date DATE
);

-- Step 2: Create a sequence for booking IDs
CREATE SEQUENCE booking_seq START WITH 1 INCREMENT BY 1;

-- Step 3: Create a procedure for making a reservation
CREATE OR REPLACE PROCEDURE make_reservation (
    p_guest_name IN VARCHAR2,
    p_contact_number IN VARCHAR2,
    p_room_type IN VARCHAR2,
    p_check_in_date IN DATE,
    p_check_out_date IN DATE
) AS
    v_guest_id NUMBER;
    v_room_id NUMBER;
BEGIN
    -- Insert guest details and fetch the generated guest_id
    INSERT INTO guests (guest_id, guest_name, contact_number)
    VALUES (guests_seq.NEXTVAL, p_guest_name, p_contact_number)
    RETURNING guest_id INTO v_guest_id;

    -- Find an available room of the requested type
    SELECT room_id INTO v_room_id
    FROM rooms
    WHERE room_type = p_room_type AND is_available = 'Y'
    FETCH FIRST 1 ROWS ONLY;

    -- Update room availability to 'N' (Not Available)
    UPDATE rooms
    SET is_available = 'N'
    WHERE room_id = v_room_id;

    -- Insert booking record
    INSERT INTO bookings (booking_id, guest_id, room_id, check_in_date, check_out_date)
    VALUES (booking_seq.NEXTVAL, v_guest_id, v_room_id, p_check_in_date, p_check_out_date);

    DBMS_OUTPUT.PUT_LINE('Reservation successfully made.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No available rooms of the requested type.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
/

-- Step 4: Create a procedure for checking in guests
CREATE OR REPLACE PROCEDURE check_in (
    p_booking_id IN NUMBER
) AS
BEGIN
    -- Ensure the booking exists
    UPDATE bookings
    SET check_in_date = SYSDATE
    WHERE booking_id = p_booking_id
    AND check_in_date IS NULL;

    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Booking not found or already checked in.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Guest successfully checked in.');
    END IF;
END;
/

-- Step 5: Create a procedure for checking out guests
CREATE OR REPLACE PROCEDURE check_out (
    p_booking_id IN NUMBER
) AS
    v_room_id NUMBER;
BEGIN
    -- Retrieve the room_id associated with the booking
    SELECT room_id INTO v_room_id
    FROM bookings
    WHERE booking_id = p_booking_id;

    -- Update room availability to 'Y' (Available)
    UPDATE rooms
    SET is_available = 'Y'
    WHERE room_id = v_room_id;

    -- Update the check-out date
    UPDATE bookings
    SET check_out_date = SYSDATE
    WHERE booking_id = p_booking_id;

    DBMS_OUTPUT.PUT_LINE('Guest successfully checked out.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Booking not found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
/

-- Step 6: Create a procedure for generating an occupancy report
CREATE OR REPLACE PROCEDURE generate_occupancy_report AS
    v_occupied_rooms NUMBER;
    v_total_rooms NUMBER;
BEGIN
    -- Count the number of occupied rooms
    SELECT COUNT(*) INTO v_occupied_rooms
    FROM rooms
    WHERE is_available = 'N';

    -- Count the total number of rooms
    SELECT COUNT(*) INTO v_total_rooms
    FROM rooms;

    DBMS_OUTPUT.PUT_LINE('Occupancy Report:');
    DBMS_OUTPUT.PUT_LINE('Total Rooms: ' || v_total_rooms);
    DBMS_OUTPUT.PUT_LINE('Occupied Rooms: ' || v_occupied_rooms);
    DBMS_OUTPUT.PUT_LINE('Vacant Rooms: ' || (v_total_rooms - v_occupied_rooms));
END;
/

-- Usage:
-- 1. Call `make_reservation` to reserve a room.
-- 2. Call `check_in` to check in a guest using the booking ID.
-- 3. Call `check_out` to check out a guest using the booking ID.
-- 4. Call `generate_occupancy_report` to see current occupancy stats.
