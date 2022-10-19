import pytest
import random
from web3 import Web3
from brownie import reverts

from scripts.helpful_scripts import (
    get_account,
    get_key_from_event,
    deploy_mocks,
    create_character_for_testing,
)
from scripts.deploy_game import deploy_game


@pytest.fixture
def populate_boss(deploy_mocks_and_game):
    _, _, world_of_ledger_contract = deploy_mocks_and_game
    owner_account = get_account()
    random_value = (
        random.randint(10, 200),
        random.randint(10, 200),
        random.randint(10, 200),
    )
    (hp, xp, reward) = random_value
    world_of_ledger_contract.populate_boss(hp, xp, reward, {"from": owner_account})


@pytest.fixture
def deploy_mocks_and_game():
    account = get_account()
    coordinator, boss_contract = deploy_mocks()
    game = deploy_game()
    subscription_id = get_key_from_event(game.tx.events[1], "subId")
    coordinator.fundSubscription(subscription_id, 100000000000, {"from": account})
    return coordinator, boss_contract, game


def test_user_may_generate_character(deploy_mocks_and_game):
    coordinator, _, world_of_ledger_contract = deploy_mocks_and_game
    not_owner_account = get_account(index=2)

    create_character_for_testing(
        coordinator, world_of_ledger_contract, not_owner_account
    )
    # assert character's isAlive is True
    assert (
        world_of_ledger_contract.usersCharacters(not_owner_account.address)[4] == True
    )
    # assert character's hp > 0
    assert world_of_ledger_contract.usersCharacters(not_owner_account.address)[0] > 0
    # assert character's damage > 0
    assert world_of_ledger_contract.usersCharacters(not_owner_account.address)[1] > 0


def test_user_may_generate_only_one_character(deploy_mocks_and_game):
    coordinator, _, world_of_ledger_contract = deploy_mocks_and_game
    not_owner_account = get_account(index=2)
    create_character_for_testing(
        coordinator, world_of_ledger_contract, not_owner_account
    )
    with reverts("You can not create more then one character"):
        create_character_for_testing(
            coordinator, world_of_ledger_contract, not_owner_account
        )
