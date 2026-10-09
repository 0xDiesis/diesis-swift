import BigInt
import Foundation
import Web3Core

/// The native currency of a Diesis network.
public struct DiesisNativeCurrency: Sendable, Equatable {
    public let name: String
    public let symbol: String
    public let decimals: Int

    public init(name: String, symbol: String, decimals: Int) {
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
    }
}

/// A Diesis network. `DiesisChain.diesis` and `DiesisChain.diesisTestnet` are
/// generated from `canonical.json`.
public struct DiesisChain: Sendable, Equatable {
    public let id: Int
    public let name: String
    public let nativeCurrency: DiesisNativeCurrency
    public let rpcURL: URL
    public let explorerURL: URL
    public let isTestnet: Bool

    public init(
        id: Int,
        name: String,
        nativeCurrency: DiesisNativeCurrency,
        rpcURL: URL,
        explorerURL: URL,
        isTestnet: Bool
    ) {
        self.id = id
        self.name = name
        self.nativeCurrency = nativeCurrency
        self.rpcURL = rpcURL
        self.explorerURL = explorerURL
        self.isTestnet = isTestnet
    }

    /// The web3swift network value for this chain ID, for
    /// `Web3HttpProvider(url:network:)`.
    public var network: Networks {
        .Custom(networkID: BigUInt(id))
    }
}
