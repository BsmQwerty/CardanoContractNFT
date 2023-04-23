{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

import Control.Monad (void, when)
import Control.Monad.Freer.Extras (LogMsg)
import Data.Aeson (FromJSON, ToJSON)
import Data.Map as Map
import Data.Text (Text)
import GHC.Generics (Generic)
import Ledger
import Ledger.Ada as Ada
import Ledger.Constraints as Constraints
import Ledger.Value as Value
import Playground.Contract (FromSchema, ToSchema)
import Plutus.Contract as Contract
import Plutus.Contracts.Currency as Currency
import Plutus.Trace.Emulator as Emulator
import System.Random (randomRIO)
import Wallet.Emulator.Types (walletPubKey)
import Wallet.Types (ContractError)

data Rarity = --Types of rarity
    deriving (Show, Eq, Ord, Generic, ToJSON, FromJSON, ToSchema, FromSchema)
data MyFT = MyFT
    { ftOwner :: PubKeyHash
    , ftTokenName :: TokenName
    , ftAmount :: Integer
    , ftOwnershipHistory :: [PubKeyHash]
    } deriving (Show, Eq, Generic, ToJSON, FromJSON, ToSchema, FromSchema)

type NFTSchema =
    BlockchainActions
        .\/ Endpoint "payUSDT" Integer
        .\/ Endpoint "payADA" Integer
        .\/ Endpoint "mint" ()
        .\/ Endpoint "transfer" (PubKeyHash, MyFT)

nftContract ::
    AsContractError e =>
    Contract NFTSchema e ()
nftContract = do
    logInfo @String "Starting NFT contract"
    selectForever $ do
        payUSDT
        payADA
        mintEndpoint
        transferEndpoint

payUSDT :: AsContractError e => Contract NFTSchema e ()
payUSDT = do
    amount <- endpoint @"payUSDT"
    payAndReceiveFT usdtCurrencySymbol usdtTokenName amount

payADA :: AsContractError e => Contract NFTSchema e ()
payADA = do
    amount <- endpoint @"payADA"
    payAndReceiveFT adaSymbol adaToken amount

mintEndpoint :: AsContractError e => Contract NFTSchema e ()
mintEndpoint = do
    _ <- endpoint @"mint"
    mintNft

transferEndpoint :: AsContractError e => Contract NFTSchema e ()
transferEndpoint = do
    (newOwner, nft) <- endpoint @"transfer"
    transferNft newOwner nft

usdtCurrencySymbol :: CurrencySymbol
usdtCurrencySymbol = "USDT"

usdtTokenName :: TokenName
usdtTokenName = "USDT"

nftCurrencySymbol :: CurrencySymbol
nftCurrencySymbol = "NFT_SYMBOL" -- Replace with the actual NFT currency symbol on Cardano

ownCurrencySymbol :: MyFT -> CurrencySymbol
ownCurrencySymbol _ = nftCurrencySymbol

mintNft :: AsContractError e => Contract NFTSchema e ()
mintNft = do
    ownPubKey <- ownPubKeyHash
    randomRarity <- liftIO chooseRarity
    let tokenName = createTokenName randomRarity
    let newNft = MyFT
            { ftOwner = ownPubKey
            , ftTokenName = tokenName
            , ftAmount = 1
            , ftOwnershipHistory = [ownPubKey]
            }

    let constraints =
            Constraints.mustMintValue (Value.singleton (ownCurrencySymbol newNft) tokenName (ftAmount newNft)) <>
            Constraints.mustPayToPubKey ownPubKey (Value.singleton usdtCurrencySymbol usdtTokenName .....) -- assuming a fixed amount of USDT for simplicity
    void $ submitTxConstraints mintConstraints constraints
    logInfo @String $ "Minted " ++ show newNft

transferNft :: AsContractError e => PubKeyHash -> MyFT -> Contract NFTSchema e ()
transferNft newOwner nft = do
    let updatedNft = nft { ftOwner = newOwner, ftOwnershipHistory = ftOwnershipHistory nft ++ [newOwner] }
    let tokenName = ftTokenName nft
    let constraints =
            Constraints.mustSpendPubKeyOutput (ftOwner nft) <>
            Constraints.mustPayToPubKey newOwner (Value.singleton (ownCurrencySymbol nft) tokenName (ftAmount nft))
    ledgerTx <- submitTxConstraintsWith @Scripts.Any mintConstraints constraints
    void $ awaitTxConfirmed $ txId ledgerTx
    logInfo @String $ "Transferred " ++ show nft ++ " to " ++ show newOwner

payAndReceiveFT :: AsContractError e => CurrencySymbol -> TokenName -> Integer -> Contract NFTSchema e ()
payAndReceiveFT currencySymbol tokenName amount = do
    when (amount < "amount number") $ throwError $ ContractError "Minimum amount required is ...."

    ownPubKey <- ownPubKeyHash
    let constraints = Constraints.mustPayToPubKey ownPubKey (Value.singleton currencySymbol tokenName amount)
    ledgerTx <- submitTxConstraintsWith @Scripts.Any mintConstraints constraints
    void $ awaitTxConfirmed $ txId ledgerTx
    logInfo @String $ "Paid to " ++ show ownPubKey
    mintNft

chooseRarity :: IO Rarity
chooseRarity = do
    randomNumber <- randomRIO (1, 10000) :: IO Int
    return $ case randomNumber of
        r | r <= --number -> rarity
        r | r <= --number-> rarity
        r | r <= --number -> rarity
        r | r <= --number -> rarity
        r | r <= --number -> rarity
        r | r <= --number-> rarity
        _ -> Common

createTokenName :: Rarity -> TokenName
createTokenName rarity = TokenName $ toBuiltin $ show rarity

main :: IO ()
main = return ()
