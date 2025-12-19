import Testing
import Foundation
import BookModel
@testable import Infrastructure

/// Tests for RecordConversion functionality
@Suite("RecordConversion Tests")
struct RecordConversionTests {

    // MARK: - BookRecord to Book2 Tests

    @Test("Valid BookRecord converts to Book2")
    func validBookRecordConversion() throws {
        let bookRecord = TestFixtures.createValidBookRecord(
            id: UUID(),
            title: "Test Book",
            author: "Test Author",
            price: 1500,
            status: "unread"
        )

        let book2 = try RecordConversion.convertToBook2(bookRecord)

        #expect(book2.id == bookRecord.id)
        #expect(book2.title == bookRecord.title)
        #expect(book2.author == bookRecord.author)
        #expect(book2.price == bookRecord.price)
        #expect(book2.status == .unread)
    }

    @Test("Status conversion: unread")
    func statusConversionUnread() throws {
        let bookRecord = TestFixtures.createValidBookRecord(status: "unread")
        let book2 = try RecordConversion.convertToBook2(bookRecord)

        #expect(book2.status == .unread)
        #expect(book2.readAt == nil)
    }

    @Test("Status conversion: reading")
    func statusConversionReading() throws {
        let bookRecord = TestFixtures.createValidBookRecord(status: "reading")
        let book2 = try RecordConversion.convertToBook2(bookRecord)

        #expect(book2.status == .reading)
        #expect(book2.readAt == nil)
    }

    @Test("Status conversion: read")
    func statusConversionRead() throws {
        let readAt = Date()
        let bookRecord = TestFixtures.createValidBookRecord(
            status: "read",
            readAt: readAt
        )
        let book2 = try RecordConversion.convertToBook2(bookRecord)

        #expect(book2.status == .read)
        #expect(book2.readAt == readAt)
    }

    @Test("Status conversion: nil defaults to unread")
    func statusConversionNilDefaultsToUnread() throws {
        let bookRecord = TestFixtures.createValidBookRecord(status: nil)
        let book2 = try RecordConversion.convertToBook2(bookRecord)

        #expect(book2.status == .unread)
    }

    @Test("Status conversion: invalid value throws error", .bug("Should handle invalid status gracefully"))
    func statusConversionInvalidThrowsError() throws {
        let bookRecord = TestFixtures.createValidBookRecord(status: "invalid_status")

        #expect(throws: RecordConversionError.self) {
            try RecordConversion.convertToBook2(bookRecord)
        }
    }

    @Test("Missing required field: id throws error")
    func missingIdThrowsError() throws {
        let bookRecord = TestFixtures.createInvalidBookRecord(id: nil)

        #expect(throws: RecordConversionError.self) {
            try RecordConversion.convertToBook2(bookRecord)
        }
    }

    @Test("Missing required field: title throws error")
    func missingTitleThrowsError() throws {
        let bookRecord = TestFixtures.createInvalidBookRecord(
            id: UUID(),
            title: nil
        )

        #expect(throws: RecordConversionError.self) {
            try RecordConversion.convertToBook2(bookRecord)
        }
    }

    @Test("Missing required field: author throws error")
    func missingAuthorThrowsError() throws {
        let bookRecord = TestFixtures.createInvalidBookRecord(
            id: UUID(),
            title: "Test",
            author: nil
        )

        #expect(throws: RecordConversionError.self) {
            try RecordConversion.convertToBook2(bookRecord)
        }
    }

    @Test("Optional fields: affiliateURL can be nil")
    func optionalAffiliateURL() throws {
        let bookRecord = TestFixtures.createValidBookRecord(affiliateURL: nil)
        let book2 = try RecordConversion.convertToBook2(bookRecord)

        #expect(book2.affiliateURL == nil)
    }

    @Test("Optional fields: caption can be nil")
    func optionalCaption() throws {
        let bookRecord = TestFixtures.createValidBookRecord(caption: nil)
        let book2 = try RecordConversion.convertToBook2(bookRecord)

        #expect(book2.caption == nil)
    }

    @Test("Default values: bought defaults to false")
    func boughtDefaultsToFalse() throws {
        let bookRecord = TestFixtures.createValidBookRecord(bought: nil)
        let book2 = try RecordConversion.convertToBook2(bookRecord)

        #expect(book2.bought == false)
    }

    @Test("Default values: note defaults to empty string")
    func noteDefaultsToEmptyString() throws {
        let bookRecord = TestFixtures.createValidBookRecord(note: nil)
        let book2 = try RecordConversion.convertToBook2(bookRecord)

        #expect(book2.note == "")
    }

    // MARK: - TagRecord to Tag2 Tests

    @Test("Valid TagRecord converts to Tag2")
    func validTagRecordConversion() throws {
        let tagRecord = TestFixtures.createValidTagRecord(
            id: UUID(),
            name: "Test Tag"
        )

        let tag2 = try RecordConversion.convertToTag2(tagRecord)

        #expect(tag2.id == tagRecord.id)
        #expect(tag2.name == tagRecord.name)
        #expect(tag2.createdAt == tagRecord.createdAt)
        #expect(tag2.updatedAt == tagRecord.updatedAt)
    }

    @Test("TagRecord missing id throws error")
    func tagMissingIdThrowsError() throws {
        let tagRecord = TestFixtures.createInvalidTagRecord(id: nil, name: "Test")

        #expect(throws: RecordConversionError.self) {
            try RecordConversion.convertToTag2(tagRecord)
        }
    }

    @Test("TagRecord missing name throws error")
    func tagMissingNameThrowsError() throws {
        let tagRecord = TestFixtures.createInvalidTagRecord(id: UUID(), name: nil)

        #expect(throws: RecordConversionError.self) {
            try RecordConversion.convertToTag2(tagRecord)
        }
    }

    // MARK: - Book-Tag Association Tests

    @Test("Extract associations: Book with no tags")
    func extractAssociationsNoTags() throws {
        let bookRecord = TestFixtures.createValidBookRecord(tags: [])
        let associations = RecordConversion.extractBookTagAssociations([bookRecord])

        #expect(associations.isEmpty)
    }

    @Test("Extract associations: Book with single tag")
    func extractAssociationsSingleTag() throws {
        let tag = TestFixtures.createValidTagRecord()
        let bookRecord = TestFixtures.createBookRecordWithTags(tags: [tag])

        let associations = RecordConversion.extractBookTagAssociations([bookRecord])

        #expect(associations.count == 1)
        #expect(associations[bookRecord.id!]?.count == 1)
        #expect(associations[bookRecord.id!]?.contains(tag.id!) == true)
    }

    @Test("Extract associations: Book with multiple tags")
    func extractAssociationsMultipleTags() throws {
        let tag1 = TestFixtures.createValidTagRecord(name: "Tag 1")
        let tag2 = TestFixtures.createValidTagRecord(name: "Tag 2")
        let tag3 = TestFixtures.createValidTagRecord(name: "Tag 3")
        let bookRecord = TestFixtures.createBookRecordWithTags(tags: [tag1, tag2, tag3])

        let associations = RecordConversion.extractBookTagAssociations([bookRecord])

        #expect(associations.count == 1)
        #expect(associations[bookRecord.id!]?.count == 3)
    }

    @Test("Extract associations: Multiple books with tags")
    func extractAssociationsMultipleBooks() throws {
        let tag1 = TestFixtures.createValidTagRecord(name: "Tag 1")
        let tag2 = TestFixtures.createValidTagRecord(name: "Tag 2")

        let book1 = TestFixtures.createBookRecordWithTags(tags: [tag1])
        let book2 = TestFixtures.createBookRecordWithTags(tags: [tag2])
        let book3 = TestFixtures.createBookRecordWithTags(tags: [tag1, tag2])

        let associations = RecordConversion.extractBookTagAssociations([book1, book2, book3])

        #expect(associations.count == 3)
        #expect(associations[book1.id!]?.count == 1)
        #expect(associations[book2.id!]?.count == 1)
        #expect(associations[book3.id!]?.count == 2)
    }

    @Test("Extract associations: Skip books with nil ID")
    func extractAssociationsSkipNilId() throws {
        let tag = TestFixtures.createValidTagRecord()
        let validBook = TestFixtures.createBookRecordWithTags(tags: [tag])
        let invalidBook = TestFixtures.createInvalidBookRecord(id: nil)

        let associations = RecordConversion.extractBookTagAssociations([validBook, invalidBook])

        #expect(associations.count == 1)
        #expect(associations[validBook.id!] != nil)
    }

    @Test("Extract associations: Skip tags with nil ID")
    func extractAssociationsSkipNilTagId() throws {
        let validTag = TestFixtures.createValidTagRecord()
        let invalidTag = TestFixtures.createInvalidTagRecord(id: nil, name: "Invalid")

        let bookRecord = TestFixtures.createBookRecordWithTags(tags: [validTag, invalidTag])

        let associations = RecordConversion.extractBookTagAssociations([bookRecord])

        #expect(associations.count == 1)
        #expect(associations[bookRecord.id!]?.count == 1)
        #expect(associations[bookRecord.id!]?.contains(validTag.id!) == true)
    }

    // MARK: - Error Message Tests

    @Test("Error message: Missing required field")
    func errorMessageMissingField() throws {
        let error = RecordConversionError.missingRequiredField("test_field")
        #expect(error.localizedDescription.contains("test_field"))
    }

    @Test("Error message: Invalid status value")
    func errorMessageInvalidStatus() throws {
        let error = RecordConversionError.invalidStatusValue("invalid")
        #expect(error.localizedDescription.contains("invalid"))
    }
}
