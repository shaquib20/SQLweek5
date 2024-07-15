CREATE PROCEDURE UpdateSubjectAllotment
AS
BEGIN
    -- Use transactions to ensure data consistency
    BEGIN TRANSACTION;

    -- Temporary table to hold the subject requests
    CREATE TABLE #SubjectRequestTemp (
        StudentID VARCHAR(255),
        SubjectID VARCHAR(255)
    );

    -- Insert the data from SubjectRequest into the temporary table
    INSERT INTO #SubjectRequestTemp
    SELECT StudentID, SubjectID FROM SubjectRequest;

    -- Cursor to iterate over each subject request
    DECLARE @StudentID VARCHAR(255);
    DECLARE @RequestedSubjectID VARCHAR(255);

    DECLARE subject_cursor CURSOR FOR
    SELECT StudentID, SubjectID FROM #SubjectRequestTemp;

    OPEN subject_cursor;

    FETCH NEXT FROM subject_cursor INTO @StudentID, @RequestedSubjectID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Check if the student exists in SubjectAllotments table
        IF EXISTS (SELECT 1 FROM SubjectAllotments WHERE StudentID = @StudentID)
        BEGIN
            -- Check the current valid subject for the student
            DECLARE @CurrentSubjectID VARCHAR(255);
            SELECT @CurrentSubjectID = SubjectID
            FROM SubjectAllotments
            WHERE StudentID = @StudentID AND Is_Valid = 1;

            -- If the current subject is different from the requested subject, update the records
            IF @CurrentSubjectID <> @RequestedSubjectID
            BEGIN
                -- Set the current valid subject to invalid
                UPDATE SubjectAllotments
                SET Is_Valid = 0
                WHERE StudentID = @StudentID AND Is_Valid = 1;

                -- Insert the new requested subject as valid
                INSERT INTO SubjectAllotments (StudentID, SubjectID, Is_Valid)
                VALUES (@StudentID, @RequestedSubjectID, 1);
            END
        END
        ELSE
        BEGIN
            -- If the student does not exist in SubjectAllotments table, insert the requested subject as valid
            INSERT INTO SubjectAllotments (StudentID, SubjectID, Is_Valid)
            VALUES (@StudentID, @RequestedSubjectID, 1);
        END

        FETCH NEXT FROM subject_cursor INTO @StudentID, @RequestedSubjectID;
    END

    CLOSE subject_cursor;
    DEALLOCATE subject_cursor;

    -- Clean up temporary table
    DROP TABLE #SubjectRequestTemp;

    -- Commit transaction
    COMMIT TRANSACTION;
END;
