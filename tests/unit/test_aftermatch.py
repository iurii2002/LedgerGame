import pytest
from scripts.helpful_scripts import (
    get_account,
    get_key_from_event,
    deploy_mocks,
    create_character_for_testing,
    create_boss_nft,
)
from scripts.deploy_game import deploy_game


@pytest.fixture
def deploy_mocks_and_game():
    account = get_account()
    coordinator, boss_contract = deploy_mocks()
    game = deploy_game()
    subscription_id_game = get_key_from_event(game.tx.events[1], "subId")
    coordinator.fundSubscription(subscription_id_game, 100000000000, {"from": account})
    coordinator.fundSubscription(
        subscription_id_game - 1, 100000000000, {"from": account}
    )
    create_boss_nft(coordinator, boss_contract, account, 3)
    return coordinator, boss_contract, game


def test_user_can_claim_rewards(deploy_mocks_and_game):
    coordinator, _, world_of_ledger_contract = deploy_mocks_and_game
    owner_account = get_account()
    hp, xp, reward = 1, 1, 100
    world_of_ledger_contract.populate_boss(hp, xp, reward, {"from": owner_account})
    not_owner_account = get_account(index=1)
    create_character_for_testing(
        coordinator, world_of_ledger_contract, not_owner_account
    )
    world_of_ledger_contract.attackBoss({"from": not_owner_account})
    world_of_ledger_contract.claimRewards({"from": not_owner_account})
    (_, _, xp, _, _, _) = world_of_ledger_contract.usersCharacters(
        not_owner_account.address
    )
    assert xp == reward


def test_reward_cleared_after_claim(deploy_mocks_and_game):
    coordinator, _, world_of_ledger_contract = deploy_mocks_and_game
    owner_account = get_account()
    hp, xp, reward = 1, 1, 100
    world_of_ledger_contract.populate_boss(hp, xp, reward, {"from": owner_account})
    not_owner_account = get_account(index=1)
    create_character_for_testing(
        coordinator, world_of_ledger_contract, not_owner_account
    )
    world_of_ledger_contract.attackBoss({"from": not_owner_account})
    world_of_ledger_contract.claimRewards({"from": not_owner_account})
    assert world_of_ledger_contract.usersRewards(not_owner_account) == 0


def test_reward_cleared_after_claim(deploy_mocks_and_game):
    coordinator, _, world_of_ledger_contract = deploy_mocks_and_game
