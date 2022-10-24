# import pytest
# from scripts.helpful_scripts import (
#     get_account,
#     get_key_from_event,
#     deploy_mocks,
#     create_character_for_testing,
#     create_boss_nft,
# )
# from scripts.deploy_game import deploy_game
# from brownie import WorldOfLedger


# @pytest.fixture
# def deploy_mocks_and_game():
#     account = get_account()
#     coordinator, boss_contract = deploy_mocks()
#     game = deploy_game()
#     subscription_id_game = get_key_from_event(game.tx.events[1], "subId")
#     coordinator.fundSubscription(subscription_id_game, 100000000000, {"from": account})
#     coordinator.fundSubscription(
#         subscription_id_game - 1, 100000000000, {"from": account}
#     )
#     create_boss_nft(coordinator, boss_contract, account, 3)
#     return coordinator, boss_contract, game
