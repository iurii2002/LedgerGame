from brownie import WorldOfLedger, config, network
from scripts.helpful_scripts import get_account, get_contract


def deploy_game():
    print(network.show_active())
    account = get_account()

    world_of_ledger = WorldOfLedger.deploy(
        get_contract("vrf_v2_coordinator"),
        config["networks"][network.show_active()]["keyHash"],
        get_contract("boss_contract"),
        get_contract("link_token"),
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    return world_of_ledger


def main():
    deploy_game()
