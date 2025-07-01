import XCTest
@testable import GraphQL

final class GraphQLTests: XCTestCase {
    struct Response: Decodable {
        struct GetPokemon: Decodable {
            let sprite: URL
            let num: Int
            let species: String
            let color: String
        }

        let getPokemon: GetPokemon
    }

    let client: GraphQL = .init(baseURL: .init(string: "https://graphqlpokemon.favware.tech/")!)

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func test_() async throws {
        let query = GraphQLQuery<Response>(
            query: """
            {
                getPokemon(pokemon: dragonite) {
                    sprite
                    num
                    species
                    color
                }
            }
            """)

        let response = try await client.send(query)

        XCTAssertNotNil(response.data)
    }
}
