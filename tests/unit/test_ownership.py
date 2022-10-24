import pytest
from scripts.helpful_scripts import get_account
from scripts.deploy_game import deploy_game
from brownie import reverts


@pytest.fixture
def world_of_ledger_contract():
    return deploy_game()


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


def test_not_owner_may_not_transfer_ownership(world_of_ledger_contract):
    not_owner_account = get_account(index=2)
    random_account = get_account(index=3)
    with reverts("Ownable: caller is not the owner"):
        world_of_ledger_contract.transferOwnership(
            random_account, {"from": not_owner_account}
        )
