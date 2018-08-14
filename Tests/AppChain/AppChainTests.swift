//
//  AppChainTests.swift
//  NervosTests
//
//  Created by Yate Fulham on 2018/08/10.
//  Copyright © 2018 Cryptape. All rights reserved.
//

import XCTest
import BigInt
@testable import Nervos

class AppChainTests: XCTestCase {
    func testPeerCount() {
        let result = nervos.appChain.peerCount()
        switch result {
        case .success(let count):
            XCTAssertTrue(count >= 0)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testBlockNumber() {
        let result = nervos.appChain.blockNumber()
        switch result {
        case .success(let blockNumber):
            XCTAssertTrue(blockNumber > 603100) // 2018-08-13
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testSendRawTransaction() {
        guard case .success(let currentBlock) = nervos.appChain.blockNumber() else { return XCTFail() }
        guard case .success(let metaData) = nervos.appChain.getMetaData() else { return XCTFail() }

        let privateKey = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        let tx = NervosTransaction(
            to: Address("0x0000000000000000000000000000000000000000")!,
            nonce: UUID().uuidString,
            data: Data.fromHex("6060604052341561000f57600080fd5b5b60646000819055507f8fb1356be6b2a4e49ee94447eb9dcb8783f51c41dcddfe7919f945017d163bf3336064604051808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018281526020019250505060405180910390a15b5b610178806100956000396000f30060606040526000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806360fe47b1146100495780636d4ce63c1461006c575b600080fd5b341561005457600080fd5b61006a6004808035906020019091905050610095565b005b341561007757600080fd5b61007f610142565b6040518082815260200191505060405180910390f35b7fc6d8c0af6d21f291e7c359603aa97e0ed500f04db6e983b9fce75a91c6b8da6b816040518082815260200191505060405180910390a1806000819055507ffd28ec3ec2555238d8ad6f9faf3e4cd10e574ce7e7ef28b73caa53f9512f65b93382604051808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018281526020019250505060405180910390a15b50565b6000805490505b905600a165627a7a723058207fbd8b51e2ecdeb2425f642d6602a4ff030351102fd7afbed80318e61fa462670029")!,
            validUntilBlock: currentBlock + 88,
            chainId: metaData.chainId
        )
        guard let signed = try? NervosTransactionSigner.sign(transaction: tx, with: privateKey) else {
            return XCTFail("Sign tx failed")
        }

        let result = nervos.appChain.sendRawTransaction(signedTx: signed)
        switch result {
        case .success(let result):
            XCTAssertTrue(result.hash.hasPrefix("0x"))
            XCTAssertEqual(66, result.hash.count)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetBlockByHash() {
        let hash = "0x70846fb609cd8876f29c7e578f4c713d399b1408002adbd689f31bc43c054eea"
        let result = nervos.appChain.getBlockByHash(hash: hash, fullTransactions: true)
        switch result {
        case .success(let block):
            XCTAssertEqual(block.hash, hash)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetBlockByNumber() {
        let number = BigUInt(603321)
        let hash = "0x70846fb609cd8876f29c7e578f4c713d399b1408002adbd689f31bc43c054eea"
        let result = nervos.appChain.getBlockByNumber(number: number, fullTransactions: true)
        switch result {
        case .success(let block):
            XCTAssertEqual(block.hash, hash)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetTransactionReceipt() {
        let result = nervos.appChain.getTransactionReceipt(txhash: "0x3466dafafb88dd0399999af3a449c923e0a48ac2bcda85396a813714079fea54")
        switch result {
        case .success(let receipt):
            XCTAssertEqual(receipt.blockHash.toHexString().addHexPrefix(), "0x70846fb609cd8876f29c7e578f4c713d399b1408002adbd689f31bc43c054eea")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetLogs() {
        var filter = Filter()
        filter.fromBlock = "0x0"
        filter.topics = [["0xe4af93ca7e370881e6f1b57272e42a3d851d3cc6d951b4f4d2e7a963914468a2", "0xa84557f35aab907f9be7974487619dd4c05be1430bf704d0c274a7b3efa50d5a", "0x00000000000000000000000000000000000000000000000000000165365f092d"]]
        let result = nervos.appChain.getLogs(filter: filter)
        switch result {
        case .success(let logs):
            XCTAssert(logs.count >= 105)
            let log = logs.first { $0.blockNumber == BigUInt(380100) }!
            XCTAssertEqual(log.blockHash.toHexString().addHexPrefix(), "0x037b6a982420b6cf61883545343708b82cb306371f919996903011fb891f3645")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testCall() {
        let request = CallRequest(from: "0x46a23e25df9a0f6c18729dda9ad1af3b6a131160", to: "0x6fc32e7bdcb8040c4f587c3e9e6cfcee4025ea58", data: "0x9507d39a000000000000000000000000000000000000000000000000000001653656eae7")
        let result = nervos.appChain.call(request: request)
        switch result {
        case .success(let data):
            XCTAssertEqual(data, "0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000568656c6c6f000000000000000000000000000000000000000000000000000000")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetTransaction() {
        let txhash = "0x3466dafafb88dd0399999af3a449c923e0a48ac2bcda85396a813714079fea54"
        let result = nervos.appChain.getTransaction(txhash: txhash)
        switch result {
        case .success(let tx):
            XCTAssertEqual(tx.hash.toHexString().addHexPrefix(), txhash)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetTransactionCountByBlockNumber() {
        let result = nervos.appChain.getTransactionCount(address: "0x4b5ae4567ad5d9fb92bc9afd6a657e6fa13a2523", blockNumber: "0x934b9")
        switch result {
        case .success(let count):
            XCTAssertEqual(count, 26)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetTransactionCountLatest() {
        let result = nervos.appChain.getTransactionCount(address: "0x4b5ae4567ad5d9fb92bc9afd6a657e6fa13a2523", blockNumber: "latest")
        switch result {
        case .success(let count):
            XCTAssertTrue(count >= 26)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetTransactionCountByAddress() {
        let address = Address("0x4b5ae4567ad5d9fb92bc9afd6a657e6fa13a2523")!
        let result = nervos.appChain.getTransactionCount(address: address, blockNumber: "latest")
        switch result {
        case .success(let count):
            XCTAssertTrue(count >= 26)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetCode() {
        let result = nervos.appChain.getCode(address: "0xd8fb3e5600a682f340761280ccf9d29c7ee114a7", blockNumber: "0x8FEC6")
        switch result {
        case .success(let code):
            XCTAssertEqual(code, "0x608060405260043610610099576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806306fdde031461009e578063095ea7b31461012e57806318160ddd1461019357806323b872dd146101be578063313ce5671461024357806370a082311461027457806395d89b41146102cb578063a9059cbb1461035b578063dd62ed3e146103c0575b600080fd5b3480156100aa57600080fd5b506100b3610437565b6040518080602001828103825283818151815260200191508051906020019080838360005b838110156100f35780820151818401526020810190506100d8565b50505050905090810190601f1680156101205780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b34801561013a57600080fd5b50610179600480360381019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803590602001909291905050506104d5565b604051808215151515815260200191505060405180910390f35b34801561019f57600080fd5b506101a86105c7565b6040518082815260200191505060405180910390f35b3480156101ca57600080fd5b50610229600480360381019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803590602001909291905050506105cd565b604051808215151515815260200191505060405180910390f35b34801561024f57600080fd5b50610258610839565b604051808260ff1660ff16815260200191505060405180910390f35b34801561028057600080fd5b506102b5600480360381019080803573ffffffffffffffffffffffffffffffffffffffff16906020019092919050505061084c565b6040518082815260200191505060405180910390f35b3480156102d757600080fd5b506102e0610895565b6040518080602001828103825283818151815260200191508051906020019080838360005b83811015610320578082015181840152602081019050610305565b50505050905090810190601f16801561034d5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b34801561036757600080fd5b506103a6600480360381019080803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190505050610933565b604051808215151515815260200191505060405180910390f35b3480156103cc57600080fd5b50610421600480360381019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803573ffffffffffffffffffffffffffffffffffffffff169060200190929190505050610b3d565b6040518082815260200191505060405180910390f35b60018054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156104cd5780601f106104a2576101008083540402835291602001916104cd565b820191906000526020600020905b8154815290600101906020018083116104b057829003601f168201915b505050505081565b600081600560003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508273ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925846040518082815260200191505060405180910390a36001905092915050565b60005481565b600081600460008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020541015801561069a575081600560008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205410155b15156106a557600080fd5b81600460008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254019250508190555081600460008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254039250508190555081600560008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600082825403925050819055508273ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef846040518082815260200191505060405180910390a3600190509392505050565b600260009054906101000a900460ff1681565b6000600460008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020549050919050565b60038054600181600116156101000203166002900480601f01602080910402602001604051908101604052809291908181526020018280546001816001161561010002031660029004801561092b5780601f106109005761010080835404028352916020019161092b565b820191906000526020600020905b81548152906001019060200180831161090e57829003601f168201915b505050505081565b600081600460003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205410158015610a035750600460008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205482600460008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205401115b1515610a0e57600080fd5b60008373ffffffffffffffffffffffffffffffffffffffff1614151515610a3457600080fd5b81600460003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254039250508190555081600460008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600082825401925050819055508273ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef846040518082815260200191505060405180910390a36001905092915050565b6000600560008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020549050929150505600a165627a7a72305820a9bfd136e48d962d0d55e57341b48830d0523279d8fa83701eda537a3c06f86d0029")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetAbi() {
        let result = nervos.appChain.getAbi(address: "0xb93b22a67D724A3487C2BD83a4aaac66F1B7C882", blockNumber: "latest")
        switch result {
        case .success(let code):
            XCTAssertEqual(code, "0x5b7b22636f6e7374616e74223a747275652c22696e70757473223a5b7b226e616d65223a22222c2274797065223a2275696e74323536227d5d2c226e616d65223a22616c6c6f7765644d656d62657273222c226f757470757473223a5b7b226e616d65223a22222c2274797065223a2261646472657373227d5d2c2270617961626c65223a66616c73652c2273746174654d75746162696c697479223a2276696577222c2274797065223a2266756e6374696f6e222c227369676e6174757265223a2230783164353563336631227d2c7b22636f6e7374616e74223a66616c73652c22696e70757473223a5b7b226e616d65223a2266696c65222c2274797065223a22737472696e67227d2c7b226e616d65223a2275726c73222c2274797065223a22737472696e67227d5d2c226e616d65223a2261646446696c65222c226f757470757473223a5b7b226e616d65223a2273756363657373222c2274797065223a22626f6f6c227d5d2c2270617961626c65223a66616c73652c2273746174654d75746162696c697479223a226e6f6e70617961626c65222c2274797065223a2266756e6374696f6e222c227369676e6174757265223a2230783234386266633362227d2c7b22636f6e7374616e74223a747275652c22696e70757473223a5b7b226e616d65223a2266696c65222c2274797065223a22737472696e67227d5d2c226e616d65223a2267657446696c6555726c73222c226f757470757473223a5b7b226e616d65223a2275726c73222c2274797065223a22737472696e67227d5d2c2270617961626c65223a66616c73652c2273746174654d75746162696c697479223a2276696577222c2274797065223a2266756e6374696f6e222c227369676e6174757265223a2230783831363234353763227d2c7b22636f6e7374616e74223a747275652c22696e70757473223a5b5d2c226e616d65223a226f776e6572222c226f757470757473223a5b7b226e616d65223a22222c2274797065223a2261646472657373227d5d2c2270617961626c65223a66616c73652c2273746174654d75746162696c697479223a2276696577222c2274797065223a2266756e6374696f6e222c227369676e6174757265223a2230783864613563623562227d2c7b22636f6e7374616e74223a66616c73652c22696e70757473223a5b7b226e616d65223a2266696c65222c2274797065223a22737472696e67227d5d2c226e616d65223a2272656d6f766546696c65222c226f757470757473223a5b7b226e616d65223a2273756363657373222c2274797065223a22626f6f6c227d5d2c2270617961626c65223a66616c73652c2273746174654d75746162696c697479223a226e6f6e70617961626c65222c2274797065223a2266756e6374696f6e222c227369676e6174757265223a2230786631616665303464227d2c7b22636f6e7374616e74223a747275652c22696e70757473223a5b7b226e616d65223a22222c2274797065223a2275696e74323536227d5d2c226e616d65223a2266696c6573222c226f757470757473223a5b7b226e616d65223a22222c2274797065223a2262797465733332227d5d2c2270617961626c65223a66616c73652c2273746174654d75746162696c697479223a2276696577222c2274797065223a2266756e6374696f6e222c227369676e6174757265223a2230786634633731346234227d2c7b22696e70757473223a5b7b226e616d65223a225f616c6c6f7765644d656d62657273222c2274797065223a22616464726573735b5d227d5d2c2270617961626c65223a66616c73652c2273746174654d75746162696c697479223a226e6f6e70617961626c65222c2274797065223a22636f6e7374727563746f72222c227369676e6174757265223a22636f6e7374727563746f72227d5d")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetBalance() {
        let result = nervos.appChain.getBalance(address: "0x4b5ae4567ad5d9fb92bc9afd6a657e6fa13a2523", blockNumber: "0x934b9")
        switch result {
        case .success(let balance):
            XCTAssertTrue(balance.toHexString().addHexPrefix() == "0xffffffffffffffffffffebdd17")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetTransactionProof() {
        let result = nervos.appChain.getTransactionProof(txhash: "0x3466dafafb88dd0399999af3a449c923e0a48ac2bcda85396a813714079fea54")
        switch result {
        case .success(let proof):
            XCTAssertEqual(proof, "0xf90c73f8d9a0316434303662306630663734343662326261363463373562626361633238383280830f42408080830000008309350f0180b841650156874f1d29985dc58b0ab4e1dd546aee08892883a124d77235bb77f17f7a5a5057715f1a4afa71da20a66cc2dda5e10e65c38bdbf7547216fb121723a7fe0080a03466dafafb88dd0399999af3a449c923e0a48ac2bcda85396a813714079fea54b840d2bdee2f7bbf540e1bef0a081f317bc8d99eb0777e6fd9e30cc1ddc220a17a0c2a18d56b4c1727149a2571a4ad25f1ff58f631c6a4ab3cd518d2fd695313acc2f9012864b9010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c019a03466dafafb88dd0399999af3a449c923e0a48ac2bcda85396a813714079fea54c0f90408a0039894316326d76d29568d7d815806a2b7286714545beda59537e3798b94728fa0ee0ac5c9b114d3312975a99262311f55f4a63108151bd312a181befb3cf5ae7aa03466dafafb88dd0399999af3a449c923e0a48ac2bcda85396a813714079fea54a0ba825f05c298f6e5de6f660adb907e7014d432488f66f86893609d62b7f0a633b9010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000830934b988ffffffffffffffff648601653106d45980b902530ace044200000000000000307862663763663035316436323066363063333531306661313362646462666435346164626239303732663231626331623131633536616334393937623639376261b834090000000000000000000000000004000000000000002a000000000000003078333130343264346637363632636464663864656435323239646233633565373330323837356531304100000000000000fa77dfd1a13785bad652da967bf187f2ba19725739a2a026f1a59c6138cbc07670a258c4e34ed1c53e5b04d04f4b7cc2d4b7f4959efe46e3404a3304b5b5bc94002a00000000000000307837316230323865343963366634316161613734393332643730336337303765636361366437333265410000000000000008d47947bd1851565ca45204e75095a9621ae95e22bd15412c1b92edd6227b974b9db3d7eefca5e775405d09aa712653959da60a8d8c7a50c56850f30d68da46012a000000000000003078656530316239626139373637316538613138393165383562323036623439396631303638323261314100000000000000214bade5b9f8114cefe7ce3d34d8758712f39671884a87a80ca7d865c5acf82e172ddb0effea6b13ba06b07b100d2bb1ec706a05c0123cec92c864411f9752ea012a000000000000003078343836626236383863386432393035366264376638376332363733333034386230613661626461364100000000000000a7a99b38d6f7e4e78f04751883ed9e2b0266e382d247900c07dc79d9f4b3fa506ac065f1638d485627e6962750c760e4f90316ac7f2b235fccb3eef6480ba6b601100294ee01b9ba97671e8a1891e85b206b499f106822a1f90408a070846fb609cd8876f29c7e578f4c713d399b1408002adbd689f31bc43c054eeaa056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421b9010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000830934ba88ffffffffffffffff808601653106e18080b902530ace044200000000000000307834353561653461633939366263633064616236643163636364323736393635303266383136346535633462643738643035323063666131343430336234363438b934090000000000000000000000000004000000000000002a00000000000000307837316230323865343963366634316161613734393332643730336337303765636361366437333265410000000000000011d8d35fe1580372913b2d7e65d711076f02282f64c6bbc197317dff4080d1d94027648629f56ab9d43a68364772a9db890535eabc0efcb2fa23f53967778821002a00000000000000307833313034326434663736363263646466386465643532323964623363356537333032383735653130410000000000000065feec95bcccf0accd8a14cf57e928d2c6d2cc976fbeb291707fb90eaf7515600528b19ac701afde60f2d01bee9d8b69af73a6ddce2cc117f9b43e1ec62e7037012a000000000000003078343836626236383863386432393035366264376638376332363733333034386230613661626461364100000000000000e324ad0a239261fd745ddd8ac135cf1f78cf05a65468d34a838978580e1c9fc12ce15372ad70e5bff00ad4a981790205bb77d198afcc6fc580d6eb2e2168b797012a000000000000003078656530316239626139373637316538613138393165383562323036623439396631303638323261314100000000000000825284b7661144300f19faf2a062d584961f3f4fc83590da4676367f68450883728092aba111bfda93f3bd7b5735442cb5077adf17ad9749f945c1ac360ffddd01100294486bb688c8d29056bd7f87c26733048b0a6abda6b902530ace044200000000000000307863656661383838323536336566616538333565623138643735646139383465346331306161616666663935643066633464646662633837343933643562343465ba34090000000000000000000000000004000000000000002a0000000000000030783331303432643466373636326364646638646564353232396462336335653733303238373565313041000000000000005cfa98db9017a9b800d46e4775838346d404160a035ff57fd0e7a6e5675b86ad66044beed79e6fda43909a0763f17ed43fa63a6a510fc67d91cae31b99ee189f002a00000000000000307837316230323865343963366634316161613734393332643730336337303765636361366437333265410000000000000009bf4d5fe4313851b62678ff1999ac13b5e40072d93a2a80b86609e990ec08155016782669fb3730bec566d175098ec4daf9373430083b8fa6b3f846b271729d012a0000000000000030783438366262363838633864323930353662643766383763323637333330343862306136616264613641000000000000003d27bbf45034b0e03c3d7ce5b0d52ce3f017841ae380dbae5af8db3be8d28b2e30b4e2b52d88061fab3e85b1c680a0f0749c5d2ea065f034e080bca458454de6012a00000000000000307865653031623962613937363731653861313839316538356232303662343939663130363832326131410000000000000006f2397e851d39bab956cfb8516596bf93e7602f715dd0c2f6764f3aaf5744ef03e2458031b71600da60d6074b9b7c906d87e35c2cfb2d530cd9d7c12bfee7e9011002")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetMetaData() {
        let result = nervos.appChain.getMetaData(blockNumber: "latest")
        switch result {
        case .success(let metaData):
            XCTAssertEqual(metaData.chainId, 1)
            XCTAssertEqual(metaData.chainName, "test-chain")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    // TODO: getBlockHeader doesn't seem to be online yet.
    func xtestGetBlockHeader() {
        let result = nervos.appChain.getBlockHeader(blockNumber: "0x934b9")
        switch result {
        case .success(let blockHeader):
            XCTAssertEqual(blockHeader, "")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    // TODO: getStateProof doesn't seem to be online yet.
    func xtestGetStateProof() {
        let result = nervos.appChain.getStateProof(address: "0xad54ae137c6c39fa413fa1da7db6463e3ae45664", key: "0xa40893b0c723e74515c3164afb5b2a310dd5854fac8823bfbffa1d912e98423e", blockNumber: "16")
        switch result {
        case .success(let proof):
            XCTAssertEqual(proof, "0xf902a594ad54ae137c6c39fa413fa1da7db6463e3ae45664f901eeb90114f9011180a088e2efeed0516020141cbbba149711e0ce67634363097a441520704040aa8dd9a0479ca451cdb343dd2eedbf313e805983e87c0f4f16e9c14f28ab3f1750eb1b8e80a0dd94e00536c62d8c801b8496fb0834ab7225954bac452a7d14c0f4a35df81074a07c689f1111314c391b164c458f902366bb18b90a53d9000a1ffd41abc96373d380808080a0b219eebc746ca232aa4a839213565d1932b4b952c93c5aa585e226ac5412d836a0b758264786a8fb6eaa6f7f2185a3f38111de3c532517ef4e46b99b80e4866d27a093ddedf515207b9a68b50f5f344aae23e709316d96345b146746ae2e511893178080a03b5530655278a731d4c895c92359fb217c64f9fde0c6945339863638396627f480b853f851808080808080808080808080a0d7a0fd35748eceb8fc8040517033416adcfb5523f4abe9789b749700c36b4ba5a0e4fe51db54afdd475e2c50888623567385f2b3694ffdb33c92a1bc782de44be7808080b880f87e942054ae137c6c39fa413fa1da7db6463e3ae45664b867f8658080a0a860517f2f639d5c3e9e8a8c04ef6c71018e18cd0881099776a73653973f90a4a00f1cd9fb6dda499878b60cdb90cf0acf25424afb5583131e4dff5e512cd64a4da0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470a0a40893b0c723e74515c3164afb5b2a310dd5854fac8823bfbffa1d912e98423ef87cb853f851a02c839c2946385ef0a820355b6969c49c97bdaa6a19b02384bcc39c992046d6b9808080808080808080a051be428c087e3544a47f273c93ffcb9999267593d3b36042a9d3e96ed068fceb808080808080a6e5a0340893b0c723e74515c3164afb5b2a310dd5854fac8823bfbffa1d912e98423e83827a02")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
}

extension AppChainTests {
    func testInvalidNode() {
        let result = nobody.appChain.peerCount()
        switch result {
        case .success(let count):
            XCTFail("Should not get peerCount \(count) from an invalid nervos node")
        case .failure(let error):
            XCTAssertNotNil(error)
        }
    }
}
