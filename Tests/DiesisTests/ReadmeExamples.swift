// The README code examples, compiled with the tests so they stay valid.
// Nothing here is called, so the tests never touch the network.

import BigInt
import Diesis
import Foundation
import Web3Core
import web3swift

enum ReadmeExamples {
    static func connect() async throws -> Web3 {
        // README: Connect
        let chain = DiesisChain.diesisTestnet
        let provider = try await Web3HttpProvider(url: chain.rpcURL, network: chain.network)
        let web3 = Web3(provider: provider)

        let blockNumber = try await web3.eth.blockNumber()  // plain web3swift still works
        _ = blockNumber
        return web3
    }

    static func read(web3: Web3) async throws -> BigUInt? {
        // README: Read a value
        let staking = web3.contract(DiesisContracts.staking)!

        let params = DiesisStaking.UnclaimedRewardsParams(tokenId: 42)
        let result = try await staking
            .createReadOperation("unclaimedRewards", parameters: [params.tokenId])!
            .callContractMethod()
        let rewards = result["0"] as? BigUInt
        return rewards
    }

    static func send(web3: Web3, privateKey: Data) async throws -> String {
        // README: Send a transaction
        let keystore = PlainKeystore(privateKey: privateKey)!
        web3.addKeystoreManager(KeystoreManager([keystore]))
        let sender = keystore.addresses!.first!

        let staking = web3.contract(DiesisContracts.staking)!
        let params = DiesisStaking.StakeParams(toValidatorId: 1)
        let operation = staking.createWriteOperation("stake", parameters: [params.toValidatorId])!
        operation.transaction.from = sender
        operation.transaction.value = Utilities.parseToBigUInt("100", units: .ether)!

        let sent = try await operation.writeToChain(password: "")
        return sent.hash
    }

    static func addresses(web3: Web3, shareAddress: EthereumAddress) {
        // README: Addresses and the contract table
        let spotBook = DiesisAddresses.diesisSpotBook
        let multicall = DiesisAddresses.multicall3

        for entry in DiesisContracts.all {
            print(entry.key, entry.name, entry.address.address)
        }

        let share = web3.contract(IValidatorShare.abi, at: shareAddress)!
        let stakeSelector = DiesisStaking.stakeSelector  // Data([0xa6, 0x94, 0xfc, 0x3a])
        _ = (spotBook, multicall, share, stakeSelector)
    }
}
