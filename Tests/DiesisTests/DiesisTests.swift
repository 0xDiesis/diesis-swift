import BigInt
import Foundation
import Web3Core
import XCTest
import web3swift

@testable import Diesis

private let repoRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()

private struct Canonical: Decodable {
    struct Currency: Decodable {
        let name: String
        let symbol: String
        let decimals: Int
    }

    struct Chain: Decodable {
        let id: Int
        let name: String
        let nativeCurrency: Currency
        let rpcUrl: String
        let explorerUrl: String
        let testnet: Bool
    }

    let schemaVersion: Int
    let chains: [String: Chain]
    let addresses: [String: String]
}

private func loadCanonical() throws -> Canonical {
    let data = try Data(contentsOf: repoRoot.appendingPathComponent("canonical.json"))
    return try JSONDecoder().decode(Canonical.self, from: data)
}

/// Keys, contract names, and address constants of the 28 fixed-address
/// contracts, in the TypeScript SDK's `diesisContracts` order.
private let expectedContracts: [(String, String, String)] = [
    ("markets", "IDiesisMarkets", "DIESIS_MARKETS"),
    ("spotBook", "IDiesisSpotBook", "DIESIS_SPOT_BOOK"),
    ("perpsBook", "IDiesisPerpsBook", "DIESIS_PERPS_BOOK"),
    ("margin", "IDiesisMargin", "DIESIS_MARGIN"),
    ("settlement", "IDiesisSettlement", "DIESIS_SETTLEMENT"),
    ("settlementRouter", "DiesisSettlementRouter", "DIESIS_SETTLEMENT_ROUTER"),
    ("conductors", "IDiesisConductors", "DIESIS_CONDUCTORS"),
    ("erc20Factory", "IDiesisErc20Factory", "DIESIS_ERC20_FACTORY"),
    ("perpDeploy", "IDiesisPerpDeploy", "DIESIS_PERP_DEPLOY"),
    ("operatorBond", "IDiesisOperatorBond", "DIESIS_OPERATOR_BOND"),
    ("bundleEscrow", "IDiesisBundleEscrow", "DIESIS_BUNDLE_ESCROW"),
    ("staking", "DiesisStaking", "DIESIS_STAKING"),
    ("position", "IDiesisPosition", "DIESIS_POSITION"),
    ("liquidStakedDS", "ILiquidStakedDS", "LIQUID_STAKED_DS"),
    ("wrappedDS", "IWrappedDS", "WRAPPED_DS"),
    ("patron", "DiesisPatron", "DIESIS_PATRON"),
    ("config", "DiesisConfig", "DIESIS_CONFIG"),
    ("coreVault", "IDiesisCoreVault", "DIESIS_CORE_VAULT"),
    ("issuanceAuction", "IDiesisIssuanceAuction", "DIESIS_ISSUANCE_AUCTION"),
    ("buybackBurn", "IDiesisBuybackBurn", "DIESIS_BUYBACK_BURN"),
    ("shieldedPool", "DiesisShieldedPool", "SHIELDED_POOL"),
    ("privacyPools", "DiesisPrivacyPools", "PRIVACY_POOLS"),
    ("nameRegistry", "IDiesisNameRegistry", "DIESIS_NAME_REGISTRY"),
    ("baseRegistrar", "DiesisBaseRegistrar", "DIESIS_BASE_REGISTRAR"),
    ("publicResolver", "DiesisPublicResolver", "DIESIS_PUBLIC_RESOLVER"),
    ("reverseRegistrar", "IDiesisReverseRegistrar", "DIESIS_REVERSE_REGISTRAR"),
    ("nameVerifier", "IDiesisNameVerifier", "DIESIS_NAME_VERIFIER"),
    ("namePolicy", "IDiesisNamePolicy", "DIESIS_NAME_POLICY"),
]

/// The ABI of every public contract, including `IValidatorShare`, which has
/// no fixed address, keyed by contract name.
private let publicABIs: [String: String] = [
    "IDiesisMarkets": IDiesisMarkets.abi,
    "IDiesisSpotBook": IDiesisSpotBook.abi,
    "IDiesisPerpsBook": IDiesisPerpsBook.abi,
    "IDiesisMargin": IDiesisMargin.abi,
    "IDiesisSettlement": IDiesisSettlement.abi,
    "DiesisSettlementRouter": DiesisSettlementRouter.abi,
    "IDiesisConductors": IDiesisConductors.abi,
    "IDiesisErc20Factory": IDiesisErc20Factory.abi,
    "IDiesisPerpDeploy": IDiesisPerpDeploy.abi,
    "IDiesisOperatorBond": IDiesisOperatorBond.abi,
    "IDiesisBundleEscrow": IDiesisBundleEscrow.abi,
    "DiesisStaking": DiesisStaking.abi,
    "IDiesisPosition": IDiesisPosition.abi,
    "IValidatorShare": IValidatorShare.abi,
    "ILiquidStakedDS": ILiquidStakedDS.abi,
    "IWrappedDS": IWrappedDS.abi,
    "DiesisPatron": DiesisPatron.abi,
    "DiesisConfig": DiesisConfig.abi,
    "IDiesisCoreVault": IDiesisCoreVault.abi,
    "IDiesisIssuanceAuction": IDiesisIssuanceAuction.abi,
    "IDiesisBuybackBurn": IDiesisBuybackBurn.abi,
    "DiesisShieldedPool": DiesisShieldedPool.abi,
    "DiesisPrivacyPools": DiesisPrivacyPools.abi,
    "IDiesisNameRegistry": IDiesisNameRegistry.abi,
    "DiesisBaseRegistrar": DiesisBaseRegistrar.abi,
    "DiesisPublicResolver": DiesisPublicResolver.abi,
    "IDiesisReverseRegistrar": IDiesisReverseRegistrar.abi,
    "IDiesisNameVerifier": IDiesisNameVerifier.abi,
    "IDiesisNamePolicy": IDiesisNamePolicy.abi,
]

final class AddressTests: XCTestCase {
    func testAddressesMatchCanonical() throws {
        let canonical = try loadCanonical()
        XCTAssertEqual(DiesisAddresses.all.count, canonical.addresses.count)
        for (constant, address) in canonical.addresses {
            let actual = try XCTUnwrap(DiesisAddresses.all[constant], constant)
            XCTAssertEqual(actual.address.lowercased(), address.lowercased(), constant)
        }
    }

    func testNamedConstants() {
        XCTAssertEqual(
            DiesisAddresses.diesisStaking.address.lowercased(),
            "0xd1e5150000000000000000000000000000000001"
        )
        XCTAssertEqual(
            DiesisAddresses.multicall3.address.lowercased(),
            "0xca11bde05977b3631167028862be2a173976ca11"
        )
    }
}

final class ChainTests: XCTestCase {
    func testChainIDs() {
        XCTAssertEqual(DiesisChain.diesis.id, 1980)
        XCTAssertEqual(DiesisChain.diesisTestnet.id, 19803)
        XCTAssertEqual(DiesisChain.diesis.network.chainID, BigUInt(1980))
        XCTAssertEqual(DiesisChain.diesisTestnet.network.chainID, BigUInt(19803))
    }

    func testChainsMatchCanonical() throws {
        let canonical = try loadCanonical()
        let pairs: [(String, DiesisChain)] = [
            ("mainnet", .diesis), ("testnet", .diesisTestnet),
        ]
        XCTAssertEqual(DiesisChain.all.count, canonical.chains.count)
        for (key, chain) in pairs {
            let expected = try XCTUnwrap(canonical.chains[key])
            XCTAssertEqual(chain.id, expected.id)
            XCTAssertEqual(chain.name, expected.name)
            XCTAssertEqual(chain.nativeCurrency.name, expected.nativeCurrency.name)
            XCTAssertEqual(chain.nativeCurrency.symbol, "DS")
            XCTAssertEqual(chain.nativeCurrency.decimals, 18)
            XCTAssertEqual(chain.rpcURL.absoluteString, expected.rpcUrl)
            XCTAssertEqual(chain.explorerURL.absoluteString, expected.explorerUrl)
            XCTAssertEqual(chain.isTestnet, expected.testnet)
        }
        XCTAssertEqual(DiesisChain.diesis.name, "Diesis")
        XCTAssertEqual(DiesisChain.diesisTestnet.name, "Diesis Testnet")
    }
}

final class ContractTableTests: XCTestCase {
    func testTableHasEveryFixedAddressContract() throws {
        let canonical = try loadCanonical()
        XCTAssertEqual(DiesisContracts.all.count, 28)
        XCTAssertEqual(DiesisContracts.all.map(\.key), expectedContracts.map(\.0))
        for (entry, (key, name, constant)) in zip(DiesisContracts.all, expectedContracts) {
            XCTAssertEqual(entry.key, key)
            XCTAssertEqual(entry.name, name)
            let expected = try XCTUnwrap(canonical.addresses[constant], constant)
            XCTAssertEqual(entry.address.address.lowercased(), expected.lowercased(), key)
            XCTAssertEqual(entry.abi, publicABIs[name], key)
        }
        XCTAssertEqual(DiesisContracts.staking.address, DiesisAddresses.diesisStaking)
    }

    func testEveryPublicContractABIParses() throws {
        XCTAssertEqual(publicABIs.count, 29)
        for (name, abi) in publicABIs {
            let contract = try EthereumContract(abi)
            XCTAssertFalse(contract.abi.isEmpty, name)
        }
    }

    func testGeneratedABIMatchesArtifact() throws {
        let contracts = ProcessInfo.processInfo.environment["DIESIS_CONTRACTS_DIR"]
            .map { URL(fileURLWithPath: $0) }
            ?? repoRoot.deletingLastPathComponent().appendingPathComponent("diesis/contracts")
        for (name, abi) in publicABIs {
            let artifact = contracts.appendingPathComponent("out/\(name).sol/\(name).json")
            guard let data = try? Data(contentsOf: artifact) else {
                throw XCTSkip("no compiled artifacts at \(contracts.path)")
            }
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            let expected = try XCTUnwrap(json["abi"] as? NSArray, name)
            let actual = try XCTUnwrap(
                JSONSerialization.jsonObject(with: Data(abi.utf8)) as? NSArray, name
            )
            XCTAssertEqual(actual, expected, name)
        }
    }

    func testGeneratedSelectorsAndTopics() throws {
        XCTAssertEqual(DiesisStaking.unclaimedRewardsSignature, "unclaimedRewards(uint256)")
        XCTAssertEqual(IWrappedDS.transferSelector, Data([0xa9, 0x05, 0x9c, 0xbb]))
        XCTAssertEqual(
            IWrappedDS.transferEventTopic,
            Data(hex: "ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef")
        )
        let staking = try DiesisContracts.staking.ethereumContract()
        let data = try XCTUnwrap(
            staking.method("unclaimedRewards", parameters: [BigUInt(1)], extraData: nil)
        )
        XCTAssertEqual(data.prefix(4), DiesisStaking.unclaimedRewardsSelector)
    }

    func testBundleEscrowUsesInitialWireSelectors() throws {
        let expected: [(String, Data)] = [
            ("reserveBundle", Data([0x79, 0x3b, 0xae, 0xf2])),
            ("finalizeBundle", Data([0x1e, 0x73, 0xb2, 0xe6])),
            ("cancelBundle", Data([0xd3, 0x07, 0xc0, 0xa3])),
            ("reclaimExpiredBundle", Data([0x3d, 0xc7, 0x27, 0xf7])),
        ]
        let actual = [
            IDiesisBundleEscrow.reserveBundleSelector,
            IDiesisBundleEscrow.finalizeBundleSelector,
            IDiesisBundleEscrow.cancelBundleSelector,
            IDiesisBundleEscrow.reclaimExpiredBundleSelector,
        ]
        XCTAssertEqual(actual, expected.map { $0.1 })
        let abi = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(IDiesisBundleEscrow.abi.utf8)) as? [[String: Any]])
        let names = abi.compactMap { $0["type"] as? String == "function" ? $0["name"] as? String : nil }
        for (name, _) in expected { XCTAssertTrue(names.contains(name), name) }
        for old in ["reserveBundleV2", "finalizeBundleV2", "cancelBundleV2", "reclaimExpiredBundleV2"] {
            XCTAssertFalse(names.contains(old), old)
        }
    }

    func testWeb3ContractAtFixedAddress() throws {
        let provider = Web3HttpProvider(url: DiesisChain.diesis.rpcURL, network: DiesisChain.diesis.network)
        let web3 = Web3(provider: provider)
        for entry in DiesisContracts.all {
            let contract = try XCTUnwrap(web3.contract(entry), entry.key)
            XCTAssertEqual(contract.contract.address, entry.address)
            XCTAssertEqual(contract.transaction.to, entry.address)
        }
    }

    func testGeneratedParamsEncodeWithWeb3swift() throws {
        let staking = try DiesisContracts.staking.ethereumContract()
        let params = DiesisStaking.UnclaimedRewardsParams(tokenId: 42)
        let data = try XCTUnwrap(staking.method("unclaimedRewards", parameters: [params.tokenId], extraData: nil))
        // selector of unclaimedRewards(uint256) followed by 42 as a uint256 word
        XCTAssertEqual(data.count, 36)
        XCTAssertEqual(data.suffix(32), Data(repeating: 0, count: 31) + Data([42]))

        let wrapped = try DiesisContracts.wrappedDS.ethereumContract()
        let transfer = IWrappedDS.TransferParams(to: DiesisAddresses.diesisStaking, amount: 1)
        XCTAssertNotNil(wrapped.method("transfer", parameters: [transfer.to, transfer.amount], extraData: nil))
    }
}
