from brownie import (
    network,
    accounts,
    config,
    LinkToken,
    VRFCoordinatorV2Mock,
    BossContract,
    Contract,
    chain,
)


FORKED_LOCAL_ENVIRONMENTS = ["mainnet-fork", "mainnet-fork-dev"]
LOCAL_BLOCKCHAIN_ENVIRONMENTS = ["development", "ganache-local"]


def get_account(index=None, id=None):
    """This function will load:
        - if no argument:
                    if local envoironment: first account of local envoironment;
                    if non-local envoironment: load wallets from config file "from_key";
        - if index argument: index account of local envoironment;
        - if id argument: loads account according to the id. The following account should be
                            stored in config file;

    Args:
        index (int): optional
        id (string): optional

    Returns:
        account
    """

    if index:
        return accounts[index]
    if id:
        return accounts.load(id)
    if (
        network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS
        or network.show_active() in FORKED_LOCAL_ENVIRONMENTS
    ):
        return accounts[0]
    return accounts.add(config["wallets"]["from_key"])


contract_to_mock = {
    "vrf_v2_coordinator": VRFCoordinatorV2Mock,
    "link_token": LinkToken,
    "boss_contract": BossContract,
}


def get_contract(contract_name):
    """This function will grab the contract addresses from the brownie config
    if defined, otherwise, it will deploy a mock version of that contract, and
    return that mock contract.

        Args:
            contract_name (string)

        Returns:
            brownie.network.contract.ProjectContract: The most recently deployed
            version of this contract.
    """
    contract_type = contract_to_mock[contract_name]
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        if len(contract_type) <= 0:
            # CONTRACT.length = 0 if not deployed already
            deploy_mocks()
        contract = contract_type[-1]
        # Else choose last one
    else:
        contract_address = config["networks"][network.show_active()][contract_name]
        # address
        # ABI
        contract = Contract.from_abi(
            contract_type._name, contract_address, contract_type.abi
        )
        # MockV3Aggregator.abi
    return contract


DECIMALS = 8
INITIAL_VALUE = 200000000000


def deploy_mocks():
    account = get_account()
    link_token = LinkToken.deploy({"from": account})
    coordinator = VRFCoordinatorV2Mock.deploy(10, 10, {"from": account})

    boss_contract = BossContract.deploy(
        "Test Boss",
        "BOSS",
        coordinator.address,
        link_token.address,
        config["networks"][network.show_active()]["keyHash"],
        {"from": account},
    )
    print("Deployed!")

    return coordinator, boss_contract


def get_key_from_event(event, _key):
    for key, value in event.items():
        if key == _key:
            return value


def create_character_for_testing(coordinator, world_of_ledger_contract, account):
    create_char_tx = world_of_ledger_contract.createRandomCharacter({"from": account})
    chain.mine(5)
    _requestId = get_key_from_event(create_char_tx.events[0], "requestId")
    coordinator.fulfillRandomWords(_requestId, world_of_ledger_contract)


def create_boss_nft(coordinator, boss_contract, account, amount=1):
    for _ in range(amount):
        tx = boss_contract.createCollectible({"from": account})
        chain.mine(5)
        id = get_key_from_event(tx.events[0], "requestId")
        coordinator.fulfillRandomWords(id, boss_contract)
