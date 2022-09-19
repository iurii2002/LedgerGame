from types import new_class
import pytest
import random
from brownie import WorldOfLedger, config, network, exceptions, reverts
from scripts.helpful_scripts import get_account
from scripts.deploy_game import deploy_game

import warnings

warnings.filterwarnings("ignore", category=DeprecationWarning)


@pytest.fixture
def world_of_ledger_contract():
    return deploy_game()


@pytest.fixture
def populate_boss(world_of_ledger_contract):
    owner_account = get_account()
    random_value = (
        random.randint(10, 200),
        random.randint(10, 200),
        random.randint(10, 200),
    )
    (hp, xp, reward) = random_value
    world_of_ledger_contract.populate_boss(hp, xp, reward, {"from": owner_account})


def test_owner_has_admin_permission(world_of_ledger_contract):
    account = get_account()
    owner_of_contract = world_of_ledger_contract.owner({"from": account})
    assert owner_of_contract == account.address


def test_owner_may_transfer_ownership(world_of_ledger_contract):
    old_owner_account = get_account()
    not_onwer_account = get_account(index=2)
    world_of_ledger_contract.transferOwnership(
        not_onwer_account, {"from": old_owner_account}
    )
    owner_of_contract = world_of_ledger_contract.owner({"from": old_owner_account})
    assert owner_of_contract == not_onwer_account.address


def test_owner_may_populate_customizable_boss(world_of_ledger_contract):
    owner_account = get_account()
    random_value = (
        random.randint(10, 200),
        random.randint(10, 200),
        random.randint(10, 200),
    )
    (hp, xp, reward) = random_value
    world_of_ledger_contract.populate_boss(hp, xp, reward, {"from": owner_account})
    # Solidity structs returns as a tuple of values
    assert world_of_ledger_contract.current_boss() == (hp, xp, reward)


def test_owner_may_not_create_boss_while_there_is_another_alive(
    world_of_ledger_contract, populate_boss
):
    owner_account = get_account()
    random_value = (
        random.randint(10, 200),
        random.randint(10, 200),
        random.randint(10, 200),
    )
    (hp, xp, reward) = random_value
    with reverts("You can not pupulate new boss while there is another alive"):
        world_of_ledger_contract.populate_boss(hp, xp, reward, {"from": owner_account})


def test_not_owner_may_not_populate_customizable_boss(world_of_ledger_contract):
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


def test_user_may_generate_character(world_of_ledger_contract):
    not_owner_account = get_account(index=2)
    world_of_ledger_contract.createRandomCharacter({"from": not_owner_account})
    # 5 as Character has 5 characteristics
    assert len(world_of_ledger_contract.usersCharacters(not_owner_account.address)) == 5


def test_user_may_generate_only_one_character(world_of_ledger_contract):
    not_owner_account = get_account(index=2)
    char1 = world_of_ledger_contract.createRandomCharacter({"from": not_owner_account})
    with reverts("You can not create more then one character"):
        char2 = world_of_ledger_contract.createRandomCharacter(
            {"from": not_owner_account}
        )


def test_user_may_attack_boss(world_of_ledger_contract, populate_boss):
    not_owner_account = get_account(index=2)
    world_of_ledger_contract.createRandomCharacter({"from": not_owner_account})
    (
        old_current_boss_hp,
        current_boss_damage,
        _,
    ) = world_of_ledger_contract.current_boss()
    (
        old_users_character_hp,
        users_character_damage,
        _,
        _,
        _,
    ) = world_of_ledger_contract.usersCharacters(not_owner_account.address)
    world_of_ledger_contract.attackBoss({"from": not_owner_account})

    (new_current_boss_hp, _, _) = world_of_ledger_contract.current_boss()
    (new_users_character_hp, _, _, _, _) = world_of_ledger_contract.usersCharacters(
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
    world_of_ledger_contract,
):
    not_owner_account_1 = get_account(index=1)
    not_owner_account_2 = get_account(index=2)
    world_of_ledger_contract.createRandomCharacter({"from": not_owner_account_1})
    world_of_ledger_contract.createRandomCharacter({"from": not_owner_account_2})
    with reverts("Only players who already earn experiences can cast the heal spell"):
        world_of_ledger_contract.healCharacter(
            not_owner_account_2, {"from": not_owner_account_1}
        )


def test_user_can_claim_rewards(world_of_ledger_contract):
    owner_account = get_account()
    hp, xp, reward = 1, 1, 100
    world_of_ledger_contract.populate_boss(hp, xp, reward, {"from": owner_account})
    not_owner_account = get_account(index=1)
    world_of_ledger_contract.createRandomCharacter({"from": not_owner_account})
    world_of_ledger_contract.attackBoss({"from": not_owner_account})
    world_of_ledger_contract.claimRewards({"from": not_owner_account})
    (_, _, xp, _, _) = world_of_ledger_contract.usersCharacters(
        not_owner_account.address
    )
    assert xp == reward


def test_user_with_experience_can_heal_other_character(world_of_ledger_contract):
    owner_account = get_account()
    hp, xp, reward = 1, 1, 100
    world_of_ledger_contract.populate_boss(hp, xp, reward, {"from": owner_account})
    not_owner_account = get_account(index=1)
    world_of_ledger_contract.createRandomCharacter({"from": not_owner_account})
    world_of_ledger_contract.attackBoss({"from": not_owner_account})
    world_of_ledger_contract.claimRewards({"from": not_owner_account})
    (_, heal_amount, xp, _, _) = world_of_ledger_contract.usersCharacters(
        not_owner_account.address
    )

    not_owner_account_2 = get_account(index=2)

    world_of_ledger_contract.createRandomCharacter({"from": not_owner_account_2})
    (old_hp, _, _, _, _) = world_of_ledger_contract.usersCharacters(
        not_owner_account_2.address
    )
    world_of_ledger_contract.healCharacter(
        not_owner_account_2, {"from": not_owner_account}
    )
    (new_hp, _, _, _, _) = world_of_ledger_contract.usersCharacters(
        not_owner_account_2.address
    )
    calculated_new_hp = old_hp + heal_amount
    assert new_hp == calculated_new_hp


def test_cant_heal_user_whithout_character(world_of_ledger_contract):
    owner_account = get_account()
    hp, xp, reward = 1, 1, 100
    world_of_ledger_contract.populate_boss(hp, xp, reward, {"from": owner_account})
    not_owner_account = get_account(index=1)
    world_of_ledger_contract.createRandomCharacter({"from": not_owner_account})
    world_of_ledger_contract.attackBoss({"from": not_owner_account})
    world_of_ledger_contract.claimRewards({"from": not_owner_account})

    not_owner_account_2 = get_account(index=2)

    with reverts("User should have Character to heal it"):
        world_of_ledger_contract.healCharacter(
            not_owner_account_2, {"from": not_owner_account}
        )


def test_reward_cleared_after_claim(world_of_ledger_contract):
    owner_account = get_account()
    hp, xp, reward = 1, 1, 100
    world_of_ledger_contract.populate_boss(hp, xp, reward, {"from": owner_account})
    not_owner_account = get_account(index=1)
    world_of_ledger_contract.createRandomCharacter({"from": not_owner_account})
    world_of_ledger_contract.attackBoss({"from": not_owner_account})
    world_of_ledger_contract.claimRewards({"from": not_owner_account})
    assert world_of_ledger_contract.usersRewards(not_owner_account) == 0
