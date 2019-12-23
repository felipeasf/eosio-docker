#!/bin/bash
set -e

# Text Properties
_equals="=============="
_newline="\n"

# Garbage Keys - Don't use these for anything official.
#_EOS_PUB_KEY="EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV"
#_EOS_PRIV_KEY="5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3"
_EOS_PUB_KEY="EOS8TzVdLNnNWYWKXaKRFC5k8DA3851Mgk7jfhxXWib6N5YXfTCyb"
_EOS_PRIV_KEY="5KXyCh714JSskkLerjGRmBaSYPvKVHazsEJfbC9bdcmrAdipEiV"

#Contracts names
_CONTRACTS_LIST=("eosio.token" "eosio.system" "eosio.msig" "ultra.bundle" "ultra.mlrp" "ultra.nft" "ultra.promoter" "ultra.shop")

# EOS Account List
_EOS_ACCOUNTS=("eosio.bpay" "eosio.msig" "eosio.names" "eosio.ram" "eosio.ramfee" "eosio.saving" "eosio.stake" "eosio.token" "eosio.vpay" "eosio.rex")

#Producer accounts
_PROD_QTY=$1
_PROD_ACCOUNTS=()

# UOS Currency Symbol and Default Amount
_EOS_AMOUNT="10000000000.0000"
_EOS_SYMBOL="UOS"
_EOS_DECIMAL_COUNT="4"

# Ultra Account Funds:
_ULTRA_AMOUNT="10000000.0000"
_ULTRA_UNSTAKED="10000000.0000"
_DUMMY_ACC_AMOUNT="10.0000"

# Working Directory
_DIRECTORY=/opt/producer/contracts
_WORKDIR=/opt/producer

# Starts from 1. Must start from 1.
ultra_id=0
ultra_id=$(( ultra_id + 1 ))

function start() {
    display_ultra
        sleep 1
# WALLET & NODEOS
    reset_wallet
    sleep 3
# EOSIO.TOKEN
    register_default_and_ultra_accs
    register_basic_contracts
    register_token_permissions
# SYSTEM
    chain_features
    register_system_contract
    register_conversion_and_tax_rates
    sleep 1
# ULTRA ACCOUNTS / CONTRACTS
    register_new_ultra_accounts
    register_ultra_contracts
# GENERATE PRODUCER ACCOUNTS
    register_producer_accounts
    resign_eosio_accounts
    register_chain_activation
}

# 0 - General Startup Function for Information
function display_ultra() {
    printf "$_newline STEP 0 $_newline"
    printf "$_newline $_equals BOOTING $_equals $_newline"
    printf "$_newline This script boots a multi-node testnet. $_newline"
    printf "$_newline If this is not what you want exit now. $_newline"
    printf "$_newline $_equals  START  $_equals $_newline"
}

# 2 - Reset Wallet
# Unlock the wallet and add all the keys we need.
function reset_wallet() {
    printf "$_newline STEP 2 $_newline"
    #clean any wallet created previously
	rm -r -f /root/eosio-wallet

	#create a wallet with its password written to ./testkeyfile
	cleos wallet create --to-console

	#import key pairs
	cleos wallet import --private-key=${_EOS_PRIV_KEY}
}

# 3 - Register Default Accounts
function register_default_and_ultra_accs() {
    printf "$_newline STEP 3 $_newline"

    mkdir $_WORKDIR/accountkeys

    for i in "${_EOS_ACCOUNTS[@]}"
    do
        # Create Account
        cleos create account eosio $i $_EOS_PUB_KEY $_EOS_PUB_KEY
    done

        #create ultra account, use the last key.
        cleos create account eosio ultra $_EOS_PUB_KEY $_EOS_PUB_KEY

}

# 4 - Activate chain features
function chain_features() {
    printf "$_newline STEP 4 $_newline"

    curl -X POST http://127.0.0.1:8888/v1/producer/schedule_protocol_feature_activations -d '{"protocol_features_to_activate": ["0ec7e080177b2c02b278d5088611686b49d739925a92d9bfcacd7fc6b74053bd"]}'

    sleep 2

    bios_directory="$_DIRECTORY/eosio.bios"

    cleos set contract eosio $bios_directory

    cleos push action eosio activate '["f0af56d2c5a48d60a4a5b5c903edfb7db3a736a94ed589d0b797df33ff9d3e1d"]' -p eosio

    cleos push action eosio activate '["2652f5f96006294109b3dd0bbde63693f55324af452b799ee137a81a905eed25"]' -p eosio

    cleos push action eosio activate '["8ba52fe7a3956c5cd3a656a3174b931d3bb2abb45578befc59f283ecd816a405"]' -p eosio

    cleos push action eosio activate '["ad9e3d8f650687709fd68f4b90b41f7d825a365b02c23a636cef88ac2ac00c43"]' -p eosio

    cleos push action eosio activate '["68dcaa34c0517d19666e6b33add67351d8c5f69e999ca1e37931bc410a297428"]' -p eosio

    cleos push action eosio activate '["e0fb64b1085cc5538970158d05a009c24e276fb94e1a0bf6a528b48fbc4ff526"]' -p eosio

    cleos push action eosio activate '["ef43112c6543b88db2283a2e077278c315ae2c84719a8b25f25cc88565fbea99"]' -p eosio

    cleos push action eosio activate '["4a90c00d55454dc5b059055ca213579c6ea856967712a56017487886a4d4cc0f"]' -p eosio

    cleos push action eosio activate '["1a99a59d87e06e09ec5b028a9cbb7749b4a5ad8819004365d02dc4379a8b7241"]' -p eosio

    cleos push action eosio activate '["4e7bf348da00a945489b2a681749eb56f5de00b900014e137ddae39f48f69d67"]' -p eosio
}

# 5 - Sets up all contracts on the nodeos system.
function register_basic_contracts() {
    printf "$_newline STEP 5 $_newline"
    token_directory="$_DIRECTORY/eosio.token"
    cleos set contract eosio.token $token_directory

    msig_directory="$_DIRECTORY/eosio.msig"
    cleos set contract eosio.msig $msig_directory
}

# 6 - Register Account Permissions Prior to Token Launch
# Fix-1 set up permison so that eosio.token can send inline with auth from itself
# fix-2 set up permission so that eosio.token can bill ram from issuer when it doesn't have signature from the issuer for a transaction such as transfer
function register_token_permissions() {
    printf "$_newline STEP 6 $_newline"
    cleos set account permission eosio.token active --add-code eosio.token owner -p eosio.token
    cleos push action eosio.token init '[]' -p ultra
    cleos push action eosio.token create '[ "ultra", "1000000000.0000 UOS"]' -p ultra
    cleos set account permission ultra active --add-code eosio.token owner -p ultra
    cleos push action eosio.token issue '["ultra","100000.0000 UOS", "Init"]' -p ultra
}

# 7 - Register System Contract
# Deploy and initiate the system contract.
function register_system_contract() {
    printf "$_newline STEP 7 $_newline"

    system_directory="$_DIRECTORY/eosio.system"

    # This just ensures the contract gets set because the transaction time may be inconsistent.
    cleos set contract eosio $system_directory -p eosio

    sleep 2

    # Initialize Systme Contract with Currency
    cleos push action eosio init '[0,"4,UOS"]' -f -p eosio

    #ultra reserve ram 1 GB
    cleos push action eosio resvrambytes '["1073741824"]' -p ultra
}

# 8 - Register Conversion and Tax Rates
function register_conversion_and_tax_rates() {
    printf "$_newline STEP 8 $_newline"
    #cleos push action eosio setconvrate '["USD","1.0000 UOS"]' -p ultra -x 1000 -f
    #cleos push action eosio setconvrate '["USD","1.0000 UOS"]' -p ultra -x 2000 -f

    # THESE NEED TO BE ADJUSTED AND LOGGED FOR FUTURE DEVELOPMENT ON LAUNCH
    cleos push action eosio setconvrate '[1, "1.0000 USD"]' -p ultra #USD
    cleos push action eosio setconvrate '[2, "1.1300 USD"]' -p ultra #EURO
    cleos push action eosio setconvrate '[3, "0.1500 USD"]' -p ultra #CNY - Chinese Yuan

    # SET TAX FOR VARIOUS RATES
    cleos push action eosio settax '[1, 0, 15]' -p ultra # USD
    cleos push action eosio settax '[2, 0, 10]' -p ultra # EUR
    cleos push action eosio settax '[3, 0, 5]' -p ultra # CNY
}

# 9 - Register New Ultra Accounts
function register_new_ultra_accounts() {
    printf "$_newline STEP 9 $_newline"
    ultranft_id=$ultra_id
	ultra_id=$(( ultra_id + 1 ))

    ultrashop_id=$ultra_id
    ultra_id=$(( ultra_id + 1 ))

    ultramlrp_id=$ultra_id
    ultra_id=$(( ultra_id + 1 ))

    ultrapromoter_id=$ultra_id
    ultra_id=$(( ultra_id + 1 ))

    ultrabundle_id=$ultra_id
    ultra_id=$(( ultra_id + 1 ))

    bitfinex_id=$ultra_id
    ultra_id=$(( ultra_id + 1 ))

	  # ultra.nft
	  cleos system newaccount ultra ultra.nft $_EOS_PUB_KEY --transfer --stake-net "5000.0000 UOS" --stake-cpu "5000.0000 UOS" --gift-ram-kbytes 2000  -p ultra --ultra-id ${ultrashop_id}

    # ultra.shop
    cleos system newaccount ultra ultra.shop $_EOS_PUB_KEY --transfer --stake-net "5000.0000 UOS" --stake-cpu "5000.0000 UOS" --gift-ram-kbytes 5000  -p ultra --ultra-id ${ultranft_id}

    # ultra.mlrp
    cleos system newaccount ultra ultra.mlrp $_EOS_PUB_KEY --transfer --stake-net "5000.0000 UOS" --stake-cpu "5000.0000 UOS" --gift-ram-kbytes 1000  -p ultra --ultra-id ${ultramlrp_id}

    # ultra.promo
    cleos system newaccount ultra ultra.promo $_EOS_PUB_KEY --transfer --stake-net "5000.0000 UOS" --stake-cpu "5000.0000 UOS" --gift-ram-kbytes 1000  -p ultra --ultra-id ${ultrapromoter_id}

    # ultra.bundle - to be added
    cleos system newaccount ultra ultra.bundle $_EOS_PUB_KEY --transfer --stake-net "5000.0000 UOS" --stake-cpu "5000.0000 UOS" --gift-ram-kbytes 1000  -p ultra --ultra-id ${ultrapromoter_id}

    # bitfinex - temporary
    cleos system newaccount ultra bitfinex $_EOS_PUB_KEY --transfer --stake-net "5000.0000 UOS" --stake-cpu "5000.0000 UOS" --gift-ram-kbytes 1000  -p ultra --ultra-id ${ultra_id}

    cleos set account permission ultra.shop active --add-code ultra.shop owner -p ultra.shop
    cleos set account permission ultra.nft active --add-code ultra.shop owner -p ultra.nft
    cleos set account permission ultra.nft active --add-code -p ultra.nft
    cleos set account permission bitfinex active --add-code ultra.shop owner -p bitfinex
    cleos set account permission ultra.bundle active --add-code ultra.bundle owner -p ultra.bundle
}

# 10 - Register Ultra Contracts
function register_ultra_contracts() {
    printf "$_newline STEP 10 $_newline"
    #NFT
    cleos set contract ultra.nft $_DIRECTORY/ultra.nft -p ultra.nft

    #MLRP
    cleos set contract ultra.mlrp $_DIRECTORY/ultra.mlrp -p ultra.mlrp
    cleos push action ultra.mlrp init '[[4,2,1], 365]' -p ultra

    #PROMO
    cleos set contract ultra.promo $_DIRECTORY/ultra.promoter -p ultra.promo

    #SHOP
    cleos set contract ultra.shop $_DIRECTORY/ultra.shop -p ultra.shop

    #BUNDLE
    cleos set contract ultra.bundle $_DIRECTORY/ultra.bundle -p ultra.bundle
}

# 11 - Generates all producer accounts.
function register_producer_accounts() {
    #generate account names based on the quantity of producers
    printf "$_newline STEP 11 $_newline"

    for i in `seq 1 $_PROD_QTY` ; do
        _PROD_ACCOUNTS+=("produceracc$i")
    done

    printf "$_newline STEP 14 $_newline"

    for i in "${_PROD_ACCOUNTS[@]}"
    do
        #x=`sed -n '2p' $_WORKDIR/$i/$i.txt`;
        #pub_key=${x:12}
        cleos system newaccount ultra --transfer $i $_EOS_PUB_KEY --stake-net "10.0000 $_EOS_SYMBOL" --stake-cpu "10.0000 $_EOS_SYMBOL" --gift-ram-kbytes 8192 -p ultra --ultra-id ${ultra_id}
        ultra_id=$(( ultra_id + 1 ))

        cleos system regproducer $i $_EOS_PUB_KEY ultra.io 0 -p ultra

    done
}

# 12 - Resign all accounts.
function resign_eosio_accounts() {
    cleos push action eosio setpriv '["eosio.msig", 1]' -p eosio@active

    printf "$_newline STEP 12 $_newline"
    for i in "${_EOS_ACCOUNTS[@]}"
    do
        first="{\"account\": \"$i\", \"permission\": \"owner\", \"parent\": \"\", \"auth\": {\"threshold\": 1, \"keys\": [], \"waits\": [], \"accounts\": [{\"weight\": 1, \"permission\": {\"actor\": \"eosio\", \"permission\": \"active\"}}]}}"
        second="{\"account\": \"$i\", \"permission\": \"active\", \"parent\": \"owner\", \"auth\": {\"threshold\": 1, \"keys\": [], \"waits\": [], \"accounts\": [{\"weight\": 1, \"permission\": {\"actor\": \"eosio\", \"permission\": \"active\"}}]}}"
        cleos push action eosio updateauth "$first" -p $i@owner
        cleos push action eosio updateauth "$second" -p $i@active
    done

    cleos set account permission eosio.token active --add-code eosio.token owner -p eosio.token

    cleos push action eosio updateauth '{"account": "eosio", "permission": "owner", "parent": "", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio.prods", "permission": "active"}}]}}' -p eosio@owner
    cleos push action eosio updateauth '{"account": "eosio", "permission": "active", "parent": "owner", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio.prods", "permission": "active"}}]}}' -p eosio@active
}

# 13 - Activate the Chain via Ultra Account
function register_chain_activation() {
    printf "$_newline STEP 13 $_newline"
    #cleos push action eosio setchainstate '[4]' -p ultra
    cleos push action eosio activatechn '[]' -p ultra
}

if [ $# -eq 0 ] || [ $1 -eq 0 ]
then
  exit 0
fi

start
