//
//  RPCTests.swift
//  AppChainTests
//
//  Created by Yate Fulham on 2018/08/10.
//  Copyright © 2018 Cryptape. All rights reserved.
//

import XCTest
import BigInt
@testable import AppChain

class RPCTests: XCTestCase {
    func testPeerCount() throws {
        let peerCount = try appChain.rpc.peerCount()
        XCTAssertTrue(peerCount > 0)
    }

    func testBlockNumber() throws {
        let blockNumber = try appChain.rpc.blockNumber()
        XCTAssertTrue(blockNumber > 100)
    }

    func testSendRawTransaction() throws {
        let currentBlock = try appChain.rpc.blockNumber()
        let metaData = try appChain.rpc.getMetaData()

        let privateKey = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        let tx = Transaction(
            to: Address("0x0000000000000000000000000000000000000000"),
            nonce: UUID().uuidString,
            validUntilBlock: currentBlock + 88,
            data: Data.fromHex("6060604052341561000f57600080fd5b60d38061001d6000396000f3006060604052600436106049576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806360fe47b114604e5780636d4ce63c14606e575b600080fd5b3415605857600080fd5b606c60048080359060200190919050506094565b005b3415607857600080fd5b607e609e565b6040518082815260200191505060405180910390f35b8060008190555050565b600080549050905600a165627a7a723058202d9a0979adf6bf48461f24200e635bc19cd1786efbcfc0608eb1d76114d405860029")!,
            chainId: metaData.chainId,
            version: metaData.version
        )
        guard let signed = try? Signer().sign(transaction: tx, with: privateKey) else {
            return XCTFail("Sign tx failed")
        }

        let result = try appChain.rpc.sendRawTransaction(signedTx: signed)
        XCTAssertEqual(32, result.hash.count)
    }

    func testSendRawTransactionPaddingValue() throws {
        let sender = Utils.publicToAddress(Utils.privateToPublic(Data.fromHex("0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")!)!)!.address.lowercased()
        XCTAssertEqual(sender, "0x46a23e25df9a0f6c18729dda9ad1af3b6a131160")

        let txhash = "0xedf58ade2ca796d6b747e51b190b3d5e95cf219035ced08d535baa4386db4d13"
        let txOnChain = try appChain.rpc.getTransaction(txhash: txhash)
        XCTAssertEqual(sender, txOnChain.unsignedTransaction!.sender.address)
    }

    func testGetBlockByHash() throws {
        let hash = "0x585f2a801f406427c09a511b0f3486326552290dec99ace0a4ccc467b48fddad"
        let block = try appChain.rpc.getBlockByHash(hash: hash, fullTransactions: true)
        XCTAssertEqual(block.hash.toHexString().addHexPrefix(), hash)
    }

    func testGetBlockByNumberNullProof() throws {
        let number = BigUInt(0)
        let block = try appChain.rpc.getBlockByNumber(number: number, fullTransactions: true)
        XCTAssertEqual(block.header.number, number)
    }

    func testGetBlockByNumber() throws {
        let number = BigUInt(1_000)
        let block = try appChain.rpc.getBlockByNumber(number: number, fullTransactions: true)
        XCTAssertEqual(block.header.number, number)
    }

    func testGetTransactionReceipt() throws {
        let receipt = try appChain.rpc.getTransactionReceipt(txhash: "0xedf58ade2ca796d6b747e51b190b3d5e95cf219035ced08d535baa4386db4d13")
        XCTAssertEqual(receipt.blockHash.toHexString().addHexPrefix(), "0x0b0c1dd58e080dc53cc3b70bbe5cb0f8fc69565778914c6f5aea82e6db7f187d")
    }

    func testGetLogs() throws {
        var filter = Filter()
        filter.fromBlock = "0x0"
        filter.topics = [["0xe4af93ca7e370881e6f1b57272e42a3d851d3cc6d951b4f4d2e7a963914468a2", "0xa84557f35aab907f9be7974487619dd4c05be1430bf704d0c274a7b3efa50d5a", "0x00000000000000000000000000000000000000000000000000000165365f092d"]]
        let logs = try appChain.rpc.getLogs(filter: filter)
        XCTAssertTrue(logs.count >= 0)
    }

    func testCall() throws {
        let request = CallRequest(from: "0x46a23e25df9a0f6c18729dda9ad1af3b6a131160", to: "0x6fc32e7bdcb8040c4f587c3e9e6cfcee4025ea58", data: "0x9507d39a000000000000000000000000000000000000000000000000000001653656eae7")
        let data = try appChain.rpc.call(request: request)
        XCTAssert(data.hasPrefix("0x"))
    }

    func testGetTransaction() throws {
        let txhash = "0xedf58ade2ca796d6b747e51b190b3d5e95cf219035ced08d535baa4386db4d13"
        let tx = try appChain.rpc.getTransaction(txhash: txhash)
        XCTAssertEqual(tx.hash.toHexString().addHexPrefix(), txhash)
        XCTAssertEqual(tx.unsignedTransaction?.sender.address, "0x46a23e25df9a0f6c18729dda9ad1af3b6a131160")
    }

    func testGetTransactionCountByBlockNumber() throws {
        let count = try appChain.rpc.getTransactionCount(address: "0x4b5ae4567ad5d9fb92bc9afd6a657e6fa13a2523", blockNumber: "0xf5dc9")
        XCTAssert(count >= 0)
    }

    func testGetTransactionCountLatest() throws {
        let count = try appChain.rpc.getTransactionCount(address: "0x4b5ae4567ad5d9fb92bc9afd6a657e6fa13a2523", blockNumber: "latest")
        XCTAssertTrue(count >= 0)
    }

    func testGetTransactionCountByAddress() throws {
        let address = Address("0x4b5ae4567ad5d9fb92bc9afd6a657e6fa13a2523")!
        let count = try appChain.rpc.getTransactionCount(address: address, blockNumber: "latest")
        XCTAssertTrue(count >= 0)
    }

    func testGetCode() throws {
        let code = try appChain.rpc.getCode(address: "0xd8fb3e5600a682f340761280ccf9d29c7ee114a7", blockNumber: "latest")
        XCTAssert(code.hasPrefix("0x"))
    }

    func testGetAbi() throws {
        let code = try appChain.rpc.getAbi(address: "0xb93b22a67D724A3487C2BD83a4aaac66F1B7C882", blockNumber: "latest")
        XCTAssert(code.hasPrefix("0x"))
    }

    func testGetBalance() throws {
        let balance = try appChain.rpc.getBalance(address: "0x4b5ae4567ad5d9fb92bc9afd6a657e6fa13a2523", blockNumber: "0xf5dc9")
        XCTAssertTrue(balance >= 0)
    }

    func testNewFilter() throws {
        var filter = Filter()
        filter.fromBlock = "0x0"
        filter.topics = [["0xe4af93ca7e370881e6f1b57272e42a3d851d3cc6d951b4f4d2e7a963914468a2", "0xa84557f35aab907f9be7974487619dd4c05be1430bf704d0c274a7b3efa50d5a", "0x00000000000000000000000000000000000000000000000000000165365f092d"]]
        let id = try appChain.rpc.newFilter(filter: filter)
        XCTAssertTrue(id > 0)
    }

    func testNewBlockFilter() throws {
        let id = try appChain.rpc.newBlockFilter()
        XCTAssertTrue(id > 0)
    }

    func testUninstallFilter() throws {
        let filterID = try appChain.rpc.newBlockFilter()
        let uninstalled = try appChain.rpc.uninstallFilter(filterID: filterID)
        XCTAssertTrue(uninstalled)

        let uninstalledAgain = try appChain.rpc.uninstallFilter(filterID: filterID)
        XCTAssertFalse(uninstalledAgain)
    }

    func testGetFilterChanges() throws {
        let changes = try appChain.rpc.getFilterChanges(filterID: 1)
        XCTAssertTrue(changes.count >= 0)
    }

    func testGetFilterLogs() throws {
        let changes = try appChain.rpc.getFilterLogs(filterID: 1)
        XCTAssertTrue(changes.count >= 0)
    }

    func testGetTransactionProof() throws {
        let proof = try appChain.rpc.getTransactionProof(txhash: "0xedf58ade2ca796d6b747e51b190b3d5e95cf219035ced08d535baa4386db4d13")
        XCTAssertEqual(proof, "0xf90d80f901dfa435323743454541312d433243302d344437412d393134462d32383444363443303539443580830f424094000000000000000000000000000000000000000080b8f06060604052341561000f57600080fd5b60d38061001d6000396000f3006060604052600436106049576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806360fe47b114604e5780636d4ce63c14606e575b600080fd5b3415605857600080fd5b606c60048080359060200190919050506094565b005b3415607857600080fd5b607e609e565b6040518082815260200191505060405180910390f35b8060008190555050565b600080549050905600a165627a7a723058202d9a0979adf6bf48461f24200e635bc19cd1786efbcfc0608eb1d76114d4058600298301b3b20180b8419d7073913db8830233ffc879c2c86b03ee0dbcf39671bed149b974ae7b715a531f3aebb930320f0058937ba6feae945a7f7b6c107e290d7c603c42af2a73bbf00180a0edf58ade2ca796d6b747e51b190b3d5e95cf219035ced08d535baa4386db4d13b840a706ad8f73115f90500266f273f7571df9429a4cfb4bbfbcd825227202dabad1ba3d35c73aec698af852b327ba1c24e11758936bb6322fe93d7469b182f66631f9012c825208b9010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0820118a0edf58ade2ca796d6b747e51b190b3d5e95cf219035ced08d535baa4386db4d13c0f9040aa077a23003c1a6ca61f26e53646a8591c40241b4ada071c49288ad18ac8aebd48aa01c59df46355f7f397a3afe22f611af6631e7bc00f39c18e6964eae71ba15e14aa0edf58ade2ca796d6b747e51b190b3d5e95cf219035ced08d535baa4386db4d13a0277560a9758981449d4e436af9cee1e7fb134186860ff9b0fc7951c59d3fd80ab90100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008301b35c88ffffffffffffffff825208860166e233160980b902530ace0442000000000000003078333936313230383063343862653434323035656366363233383833383163363536633033366362356639346661363138396537653463336136353637303762345bb3010000000000000000000000000004000000000000002a00000000000000307834393763363866303262626533333563633837393335366166313230333731656266366362633239410000000000000000076a893c8e39f0df7262f1679edd5c4c324425796b94a35c5b3f66be3b2ebb284e35b0badc44e3e55a44945a8fa0c00e671535b76e9c5c48255d5a16fddc5d012a000000000000003078633438396435636236663439376534373038636338633338303534373362393532386638336337614100000000000000156729a2aa9004c6881fbfa015af57c0123cc6ee1c99759cd9216a7b19ae3dcf08df592e00205e66eee9de50e4244effb5a36a21b0fca1ae6dd322cba326dec3002a0000000000000030783666626234633862623736616365363331643633343534356665333963626565393739646430386541000000000000001073561a3b7b0f122fdb09efe573f4a94bed46981d797fe186ca69a9e37843ee4955b4ed349678b96781cc91a165f46f6b3324f32fa442b7033be3b8b128c5b4012a00000000000000307833633066363831653133663138623531643533353038323365616534356362353032323331636634410000000000000011f93aa64b4c0a14c4cfbc4b8b7420aa1783aa070fead855d584afddc043d6d071c8c33181e8fda50b991e79c80b6c5ce5c06b6b99a315be9b02071e30322ebf00100294c489d5cb6f497e4708cc8c3805473b9528f83c7af90408a00b0c1dd58e080dc53cc3b70bbe5cb0f8fc69565778914c6f5aea82e6db7f187da056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421b90100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008301b35d88ffffffffffffffff80860166e2331ace80b902530ace0442000000000000003078383438666635643936336232663831396438323539313362396439356235666436363162343663393662646131303734653362376430323436643536623037325cb3010000000000000000000000000004000000000000002a000000000000003078633438396435636236663439376534373038636338633338303534373362393532386638336337614100000000000000deef4a33b804fafc77f8afdef1fbf6040f8390f62d73dfddadb9f6abe4ef4e102c1ec56aa2592e31f6bd5d2f23c35410f0b724828d6997a5cad42d0147efc94b002a000000000000003078343937633638663032626265333335636338373933353661663132303337316562663663626332394100000000000000dd385a93afe90f7335a0fad9b6b3f25367454f3e766d4566133e8c8a232d353322e3d354a90370bce540f16d984232591a489226ef7b5f35b869bd6b0e3e47e4012a00000000000000307836666262346338626237366163653633316436333435343566653339636265653937396464303865410000000000000067548cfd3c2c4dc08cc1d2bb5bf283750f6ab3c83938bd61d2653610c9c115b44e813aa4a84c8ddb4a208a9d032b1cf62f4f1a3ceb3775371df4c8e2a3ea4fc1002a0000000000000030783363306636383165313366313862353164353335303832336561653435636235303232333163663441000000000000008f09cad1ec4f66091af5c6e60f5c88764c7dacbba6576aba42ae1d65f99b1f1a49566313388e8b11b4c7547bf5bfba558ba50a5e527ef11d982a9bd0d629bf9700100294497c68f02bbe335cc879356af120371ebf6cbc29b902530ace0442000000000000003078313537383332616465643063303364636566366639323838616337313232623631386333636434356339336666356161386435353530636635373034363563355db3010000000000000000000000000004000000000000002a000000000000003078336330663638316531336631386235316435333530383233656165343563623530323233316366344100000000000000626a2041818d9d5ed89b9b014fd892a53296242e6a6d44829cfb930b29634b1b5468ef7cf1eb2a3336e2f0abd26c12d28d5d1464c5d977fd4b967d0e1f902c44012a000000000000003078633438396435636236663439376534373038636338633338303534373362393532386638336337614100000000000000e7a11b149b14f6bde58cc68807295f82de3438f742f868d7d40fd6f402af84fe570595e851ec4a8bee10893fca43e864b6e4dcf4fd9a75891bc18c4c983a2996002a000000000000003078343937633638663032626265333335636338373933353661663132303337316562663663626332394100000000000000831d9bc0570c5bbfb2cfac5eaa1ab53663424c7e08dd55469a5710a48f42b405472002c09a7051c5b64d16bb55f23ef431f867f346c615a733c47d8a9752b1be012a0000000000000030783666626234633862623736616365363331643633343534356665333963626565393739646430386541000000000000001c87e06acfb3a16d393a11a40f94e533dfb6f59923d66a0595890ae84ec032244e539f92e640a5bc3bb44f0ad16d992665e7dfb3adbe127591a48e0a5ac48f99001002")
    }

    func testGetMetaData() throws {
        let metaData = try appChain.rpc.getMetaData(blockNumber: "latest")
        XCTAssertEqual(metaData.chainName, "test-chain")
    }

    func testGetBlockHeader() throws {
        let blockNumber = try appChain.rpc.blockNumber()
        let blockHeader = try appChain.rpc.getBlockHeader(blockNumber: blockNumber - 1)
        XCTAssert(blockHeader.hasPrefix("0x"))
    }

    func xtestGetStateProof() throws {
        let proof = try appChain.rpc.getStateProof(address: "0xad54ae137c6c39fa413fa1da7db6463e3ae45664", key: "0xa40893b0c723e74515c3164afb5b2a310dd5854fac8823bfbffa1d912e98423e", blockNumber: "latest")
        XCTAssertEqual(proof, "0xf902a594ad54ae137c6c39fa413fa1da7db6463e3ae45664f901eeb90114f9011180a088e2efeed0516020141cbbba149711e0ce67634363097a441520704040aa8dd9a0479ca451cdb343dd2eedbf313e805983e87c0f4f16e9c14f28ab3f1750eb1b8e80a0dd94e00536c62d8c801b8496fb0834ab7225954bac452a7d14c0f4a35df81074a07c689f1111314c391b164c458f902366bb18b90a53d9000a1ffd41abc96373d380808080a0b219eebc746ca232aa4a839213565d1932b4b952c93c5aa585e226ac5412d836a0b758264786a8fb6eaa6f7f2185a3f38111de3c532517ef4e46b99b80e4866d27a093ddedf515207b9a68b50f5f344aae23e709316d96345b146746ae2e511893178080a03b5530655278a731d4c895c92359fb217c64f9fde0c6945339863638396627f480b853f851808080808080808080808080a0d7a0fd35748eceb8fc8040517033416adcfb5523f4abe9789b749700c36b4ba5a0e4fe51db54afdd475e2c50888623567385f2b3694ffdb33c92a1bc782de44be7808080b880f87e942054ae137c6c39fa413fa1da7db6463e3ae45664b867f8658080a0a860517f2f639d5c3e9e8a8c04ef6c71018e18cd0881099776a73653973f90a4a00f1cd9fb6dda499878b60cdb90cf0acf25424afb5583131e4dff5e512cd64a4da0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470a0a40893b0c723e74515c3164afb5b2a310dd5854fac8823bfbffa1d912e98423ef87cb853f851a02c839c2946385ef0a820355b6969c49c97bdaa6a19b02384bcc39c992046d6b9808080808080808080a051be428c087e3544a47f273c93ffcb9999267593d3b36042a9d3e96ed068fceb808080808080a6e5a0340893b0c723e74515c3164afb5b2a310dd5854fac8823bfbffa1d912e98423e83827a02")
    }
}
