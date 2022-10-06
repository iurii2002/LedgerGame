from types import new_class
import pytest
import random
from web3 import Web3
from brownie import (
    WorldOfLedger,
    config,
    network,
    exceptions,
    reverts,
    chain,
    VRFCoordinatorV2Mock,
)
from scripts.helpful_scripts import (
    get_account,
    get_key_from_event,
    deploy_mocks,
    create_character_for_testing,
)
from scripts.deploy_game import deploy_game

import warnings

warnings.filterwarnings("ignore", category=DeprecationWarning)


# @pytest.fixture
# def world_of_ledger_contract():
#     return deploy_game()


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


def test_owner_has_admin_permission(deploy_mocks_and_game):
    coordinator, _, world_of_ledger_contract = deploy_mocks_and_game
    account = get_account()
    owner_of_contract = world_of_ledger_contract.owner({"from": account})
    assert owner_of_contract == account.address


def test_owner_may_transfer_ownership(deploy_mocks_and_game):
    coordinator, _, world_of_ledger_contract = deploy_mocks_and_game
    old_owner_account = get_account()
    not_onwer_account = get_account(index=2)
    world_of_ledger_contract.transferOwnership(
        not_onwer_account, {"from": old_owner_account}
    )
    owner_of_contract = world_of_ledger_contract.owner({"from": old_owner_account})
    assert owner_of_contract == not_onwer_account.address


def test_owner_may_populate_customizable_boss(deploy_mocks_and_game):
    coordinator, boss_contract, world_of_ledger_contract = deploy_mocks_and_game
    # boss_contract.
    owner_account = get_account()
    random_value = (
        random.randint(10, 200),
        random.randint(10, 200),
        random.randint(10, 200),
    )
    (hp, xp, reward) = random_value
    print(random_value)
    print("mass contract ", boss_contract.getMaxSupply())
    populate_boss_tx = world_of_ledger_contract.populate_boss(
        hp, xp, reward, {"from": owner_account}
    )
    id = get_key_from_event(populate_boss_tx.events[0], "bossID")
    assert world_of_ledger_contract.currentBoss() == (hp, xp, reward, id)


def test_owner_may_not_create_boss_while_there_is_another_alive(
    deploy_mocks_and_game, populate_boss
):
    coordinator, _, world_of_ledger_contract = deploy_mocks_and_game
    owner_account = get_account()
    random_value = (
        random.randint(10, 200),
        random.randint(10, 200),
        random.randint(10, 200),
    )
    (hp, xp, reward) = random_value
    with reverts("You can not pupulate new boss while there is another alive"):
        world_of_ledger_contract.populate_boss(hp, xp, reward, {"from": owner_account})


def test_notowner_may_not_populate_customizable_boss(deploy_mocks_and_game):
    coordinator, _, world_of_ledger_contract = deploy_mocks_and_game
    not_owner_account = get_account(index=2)
    random_value = (
        random.randint(10, 200),
        random.randint(10, 200),
        random.randint(10, 200),
    )
    (hp, xp, reward) = random_value
    with reverts():
        world_of_ledger_contract.populate_boss(
            hp, xp, reward, {"from": not_owner_account}
        )


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


def test_user_may_attack_boss(deploy_mocks_and_game, populate_boss):
    # pytest.skip("does not work for some reason")
    coordinator, _, world_of_ledger_contract = deploy_mocks_and_game
    not_owner_account = get_account(index=2)

    create_character_for_testing(
        coordinator, world_of_ledger_contract, not_owner_account
    )
    print(world_of_ledger_contract.usersCharacters(not_owner_account.address))
    (
        old_users_character_hp,
        users_character_damage,
        _,
        _,
        _,
        _,
    ) = world_of_ledger_contract.usersCharacters(not_owner_account.address)

    (
        old_current_boss_hp,
        current_boss_damage,
        _,
        _,
    ) = world_of_ledger_contract.currentBoss()

    attack_tx = world_of_ledger_contract.attackBoss({"from": not_owner_account})
    (new_current_boss_hp, _, _, _) = world_of_ledger_contract.currentBoss()
    (new_users_character_hp, _, _, _, _, _) = world_of_ledger_contract.usersCharacters(
        not_owner_account.address
    )
    calculated_boss_hp = (
        old_current_boss_hp - users_character_damage
        if old_current_boss_hp > users_character_damage
        else 0
    )
    calculated_users_character_hp = (
        old_users_character_hp - current_boss_damage
        if old_users_character_hp > current_boss_damage
        else 0
    )

    assert new_current_boss_hp == calculated_boss_hp
    assert new_users_character_hp == calculated_users_character_hp


def test_user_without_experience_can_not_heal_other_character(
    deploy_mocks_and_game,
):
    coordinator, _, world_of_ledger_contract = deploy_mocks_and_game
    not_owner_account_1 = get_account(index=1)
    not_owner_account_2 = get_account(index=2)

    create_character_for_testing(
        coordinator, world_of_ledger_contract, not_owner_account_1
    )
    create_character_for_testing(
        coordinator, world_of_ledger_contract, not_owner_account_2
    )

    with reverts("Only players who already earn experiences can cast the heal spell"):
        world_of_ledger_contract.healCharacter(
            not_owner_account_2, {"from": not_owner_account_1}
        )


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


def test_user_with_experience_can_heal_other_character(deploy_mocks_and_game):
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
    (_, heal_amount, xp, _, _, _) = world_of_ledger_contract.usersCharacters(
        not_owner_account.address
    )

    not_owner_account_2 = get_account(index=2)

    create_character_for_testing(
        coordinator, world_of_ledger_contract, not_owner_account_2
    )

    (old_hp, _, _, _, _, _) = world_of_ledger_contract.usersCharacters(
        not_owner_account_2.address
    )
    world_of_ledger_contract.healCharacter(
        not_owner_account_2, {"from": not_owner_account}
    )
    (new_hp, _, _, _, _, _) = world_of_ledger_contract.usersCharacters(
        not_owner_account_2.address
    )
    calculated_new_hp = old_hp + heal_amount
    assert new_hp == calculated_new_hp


def test_cant_heal_user_whithout_character(deploy_mocks_and_game, populate_boss):
    coordinator, _, world_of_ledger_contract = deploy_mocks_and_game
    not_owner_account = get_account(index=1)
    create_character_for_testing(
        coordinator, world_of_ledger_contract, not_owner_account
    )
    world_of_ledger_contract.attackBoss({"from": not_owner_account})
    world_of_ledger_contract.claimRewards({"from": not_owner_account})

    not_owner_account_2 = get_account(index=2)

    with reverts("User should have Character to heal it"):
        world_of_ledger_contract.healCharacter(
            not_owner_account_2, {"from": not_owner_account}
        )


def test_player_less_then_level3_cant_cast_fireBolt(
    deploy_mocks_and_game, populate_boss
):
    coordinator, _, world_of_ledger_contract = deploy_mocks_and_game
    not_owner_account = get_account(index=2)

    create_character_for_testing(
        coordinator, world_of_ledger_contract, not_owner_account
    )

    with reverts("Only players level 3 or above may cast the heal spell"):
        world_of_ledger_contract.castFireBolt({"from": not_owner_account})


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
