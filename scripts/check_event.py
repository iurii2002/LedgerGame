from web3 import Web3
import json

infura_url = "https://goerli.infura.io/v3/7755d5bcc3fe48e39078a9b963f1f3bf"
w3 = Web3(Web3.HTTPProvider(infura_url))


def main():
    with open("./build/contracts/WorldOfLedger.json") as f:
        f = json.load(f)
        contract = w3.eth.contract(
            address="0x3B5017c6a13aeD57a0ec3D86cA836996Cf83619b", abi=f["abi"]
        )

        new_filter = contract.events.BossCreated.createFilter(fromBlock=7700000)
        print(new_filter.get_all_entries())
        # print(new_filter.get_new_entries())
