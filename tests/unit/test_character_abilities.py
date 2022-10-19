import pytest
import random
from brownie import reverts, chain

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


def test_user_may_attack_boss(deploy_mocks_and_game):
    coordinator, boss_contract, world_of_ledger_contract = deploy_mocks_and_game
    owner_account = get_account()
    not_owner_account = get_account(index=2)

    create_character_for_testing(
        coordinator, world_of_ledger_contract, not_owner_account
    )

    world_of_ledger_contract.populate_boss(1, 1, 1, {"from": owner_account})

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
    coordinator, boss_contract, world_of_ledger_contract = deploy_mocks_and_game
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


def test_cant_heal_user_whithout_character(deploy_mocks_and_game):
    coordinator, boss_contract, world_of_ledger_contract = deploy_mocks_and_game
    owner_account = get_account()
    not_owner_account = get_account(index=1)
    create_character_for_testing(
        coordinator, world_of_ledger_contract, not_owner_account
    )

    world_of_ledger_contract.populate_boss(1, 1, 1, {"from": owner_account})
    world_of_ledger_contract.attackBoss({"from": not_owner_account})
    world_of_ledger_contract.claimRewards({"from": not_owner_account})

    not_owner_account_2 = get_account(index=2)

    with reverts("User should have Character to heal it"):
        world_of_ledger_contract.healCharacter(
            not_owner_account_2, {"from": not_owner_account}
        )


def test_player_less_then_level3_cant_cast_fireBolt(deploy_mocks_and_game):
    coordinator, boss_contract, world_of_ledger_contract = deploy_mocks_and_game
    not_owner_account = get_account(index=2)
    owner_account = get_account()
    world_of_ledger_contract.populate_boss(1, 1, 1, {"from": owner_account})

    create_character_for_testing(
        coordinator, world_of_ledger_contract, not_owner_account
    )

    with reverts("Only players level 3 or above may cast the heal spell"):
        world_of_ledger_contract.castFireBolt({"from": not_owner_account})


def test_user_with_experience_can_heal_other_character(deploy_mocks_and_game):
    coordinator, boss_contract, world_of_ledger_contract = deploy_mocks_and_game
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
