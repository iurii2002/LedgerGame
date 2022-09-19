from brownie import WorldOfLedger, config, network
from scripts.helpful_scripts import get_account


def deploy_game():
    print(network.show_active())
    account = get_account()
    world_of_ledger = WorldOfLedger.deploy(
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    return world_of_ledger


def main():
    deploy_game()
