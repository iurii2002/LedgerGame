import pytest
import random
from brownie import reverts
from scripts.helpful_scripts import (
    get_account,
    get_key_from_event,
    deploy_mocks,
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


def test_owner_may_populate_customizable_boss(deploy_mocks_and_game):
    coordinator, boss_contract, world_of_ledger_contract = deploy_mocks_and_game
    owner_account = get_account()
    random_values = (
        random.randint(10, 200),
        random.randint(10, 200),
        random.randint(10, 200),
    )
    (hp, xp, reward) = random_values

    populate_boss_tx = world_of_ledger_contract.populate_boss(
        hp, xp, reward, {"from": owner_account}
    )
    id = get_key_from_event(populate_boss_tx.events[0], "bossID")
    assert world_of_ledger_contract.currentBoss() == (hp, xp, reward, id)


def test_owner_may_not_create_boss_while_there_is_another_alive(deploy_mocks_and_game):
    coordinator, boss_contract, world_of_ledger_contract = deploy_mocks_and_game
    owner_account = get_account()
    random_values = (
        random.randint(10, 200),
        random.randint(10, 200),
        random.randint(10, 200),
    )
    (hp, xp, reward) = random_values
    # creating first boss
    world_of_ledger_contract.populate_boss(hp, xp, reward, {"from": owner_account})
    with reverts("You can not pupulate new boss while there is another alive"):
        # creating second boss
        world_of_ledger_contract.populate_boss(hp, xp, reward, {"from": owner_account})


def test_notowner_may_not_populate_customizable_boss(deploy_mocks_and_game):
    coordinator, boss_contract, world_of_ledger_contract = deploy_mocks_and_game
    not_owner_account = get_account(index=2)
    random_values = (
        random.randint(10, 200),
        random.randint(10, 200),
        random.randint(10, 200),
    )
    (hp, xp, reward) = random_values
    with reverts():
        world_of_ledger_contract.populate_boss(
            hp, xp, reward, {"from": not_owner_account}
        )
