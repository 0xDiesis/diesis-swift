import Web3Core
import web3swift

/// A public system contract at its fixed address. See `DiesisContracts`.
public struct DiesisContract: Sendable, Equatable {
    /// The key used by the TypeScript SDK's `diesisContracts`, such as `staking`.
    public let key: String
    /// The Solidity contract or interface name, such as `DiesisStaking`. The
    /// generated enum of the same name holds the contract's ABI, selectors,
    /// and parameter, event, error, and tuple structs.
    public let name: String
    public let address: EthereumAddress
    /// The contract ABI as a JSON array string, from the generated enum.
    public let abi: String

    public init(key: String, name: String, address: EthereumAddress, abi: String) {
        self.key = key
        self.name = name
        self.address = address
        self.abi = abi
    }

    /// Parses the ABI with web3swift.
    public func ethereumContract() throws -> EthereumContract {
        try EthereumContract(abi, at: address)
    }
}

extension Web3 {
    /// A web3swift contract object for a Diesis system contract at its fixed
    /// address. Returns `nil` only if web3swift cannot parse the ABI.
    public func contract(_ contract: DiesisContract) -> Web3.Contract? {
        self.contract(contract.abi, at: contract.address)
    }
}
