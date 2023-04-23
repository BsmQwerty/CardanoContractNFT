# CardanoContractNFT
A simple contract that uses randomness. When someone pays the indicated amount of ADA or USDT, a FT with a drawn rarity is minted and sent to his address.
The contract includes the following main components:

    1. Data types Rarity and MyFT: Rarity represents the rarity levels of the NFTs (Mythical, Legendary, Special, Epic, Rare, Uncommon, and Common), while MyFT stores the information of an NFT, including its owner, token name, amount, and ownership history.
    
    2. Endpoint schema NFTSchema: This schema defines the endpoints available to interact with the smart contract, including "payUSDT", "payADA", "mint", and "transfer".
    
    3. Main contract function nftContract: This function initializes the contract and starts listening to the defined endpoints.
    
    4. Payment functions payUSDT and payADA: These functions handle the payment process in either USDT or ADA. They ensure that the user pays the minimum required amount (1,000,000 in this example) and then call the mintNft function to create a new NFT.
    
    5. Minting function mintNft: This function randomly chooses a rarity for the new NFT, creates a token name based on the rarity, and mints the NFT. It also requires the user to pay a fixed amount of USDT.
    
    6. Transfer function transferNft: This function transfers an NFT from the current owner to a new owner. It updates the ownership history of the NFT accordingly.
    
    7. Helper functions chooseRarity and createTokenName: These functions randomly choose a rarity for a new NFT and create a token name based on the chosen rarity.
