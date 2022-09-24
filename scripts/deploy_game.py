from brownie import WorldOfLedger, config, network
from scripts.helpful_scripts import get_account, get_contract


def deploy_game():
    print(network.show_active())
    account = get_account()

    world_of_ledger = WorldOfLedger.deploy(
        config["networks"][network.show_active()]["subscriptionId"],
        config["networks"][network.show_active()]["VRF_coordinator"],
        config["networks"][network.show_active()]["keyHash"],
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    # world_of_ledger = WorldOfLedger.deploy(
    #     config["networks"][network.show_active()]["subscriptionId"],
    #     get_contract("VRF_V2_coordinator"),
    #     config["networks"][network.show_active()]["keyHash"],
    #     {"from": account},
    #     publish_source=config["networks"][network.show_active()].get("verify", False),
    # )
    return world_of_ledger


def main():
    deploy_game()
