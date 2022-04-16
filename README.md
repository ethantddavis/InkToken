# Ink yield token for Sad Bears Club NFT project. 

<h2>Description</h2>
 
 The INK token has a supply of 101,378,750 and is able to be claimed by holders of Sad Bears Club NFT's at a rate of 5 tokens daily. The NFT contract was first written by Andrew Olsen. Ink contract is live on mainnet at 0x56c29446De7Fb1584B349468b3b3bdA3638f23e3
  


Contract full deployment checklist (remix) for testing

1. compile Ink.sol and bearsNFT.sol in remix
2. deploy bearsNFt.sol
3. deploy Ink.sol with bearsNFT contract address
4. call bearsNFT setYieldToken (Ink contract address)
5. call bearsNFT setCost (0)
6. call bearsNFT setPublicMint (true)
7. call bearsNFT setPaused (false)
8. call bearsNFT mint (amount 1 - 5)
9. call bearsNFT balanceOf (your address) 
10. call Ink.sol getPendingReward()

quick deploy ROPSTEN

- bears NFT contract address: 0x9b6529c6C915dbC0FE2851D822046742E8c00c93
- ink token contract address: 0xB82e8616ef29d96B867e37a16bFaB878766E4519
