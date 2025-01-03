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

-- Step 2: Create sequences for guest IDs and booking IDs
CREATE SEQUENCE guests_seq START WITH 1 INCREMENT BY 1;
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
    FOR UPDATE SKIP LOCKED;

    -- Update room availability
    UPDATE rooms
    SET is_available = 'N'
    WHERE room_id = v_room_id;

    -- Insert booking details
    INSERT INTO bookings (booking_id, guest_id, room_id, check_in_date, check_out_date)
    VALUES (booking_seq.NEXTVAL, v_guest_id, v_room_id, p_check_in_date, p_check_out_date);

    COMMIT;
END;
/