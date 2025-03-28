from web3 import Web3
from tee import SimTEE


class SimREE:

    def __init__(self):
        self.localAddress = SimTEE()
        self.path = 'https://localhost:8545'
        self.w3 = Web3(Web3.HTTPProvider(self.path))

    def isConnected(self) -> bool:
        return self.w3.isConnected()


    contractABI = [
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "account",
				"type": "address"
			}
		],
		"name": "getAccountBalance",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	}
]