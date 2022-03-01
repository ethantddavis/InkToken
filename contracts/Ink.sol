// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract InkToken is ERC20 {

    uint256 constant public MAX_SUPPLY = 101378750 ether;
	uint256 constant public INTERVAL = 86400; 
    uint256 constant public NFTReward = 5;

	mapping(address => uint256) private lastUpdate; // record when user interacts with contract

	IERC721 public NFTContract;  

	event RewardPaid(address indexed user, uint256 reward); 
 
    constructor(address NFTContractAddress) ERC20("Sad Bears Club Ink", "INK") {

        NFTContract = IERC721(NFTContractAddress);
    }

    /* * * * * * * * * * * * * * * GASLESS GET FUNCTIONS * * * * * * * * * * * * * * */

    // returns the last timestamp user interacted with the contract
    function getLastUpdate(address user) external view returns(uint256) {
        
        return lastUpdate[user];
    }

    // return the number of SBC NFTs user owns
    function getNFTBalance(address user) public view returns (uint256) {

        return NFTContract.balanceOf(user);
    }

    // returns the entire reward a user will recieve when they claim
    function getPendingReward(address user) public view returns(uint256) { 
        // (block.timestamp - lastUpdate[user]) / INTERVAL = number of days
        // getNFTBalance(user) * NFTReward = cumulative daily reward for user
        // 1 ether = 1000000000000000000
        return (getNFTBalance(user) * NFTReward) * (1 ether * (block.timestamp - lastUpdate[user])) / INTERVAL;
    }

    /* * * * * * * * * * * * * * * USER GAS FUNCTIONS * * * * * * * * * * * * * * */

    // pay out the holder
    function claimReward() public { 
        require(totalSupply() < MAX_SUPPLY, "INK collection is over"); // INK earned will not be claimable after max INK has been minted
        require(getNFTBalance(msg.sender) > 0, "You must own a SBC NFT to claim rewards");

        pay(msg.sender, getPendingReward(msg.sender));

        lastUpdate[msg.sender] = block.timestamp; 
    }

    /* * * * * * * * * * * * * * * HELPER FUNCTIONS * * * * * * * * * * * * * * */
    
    // mints the user appropriate amount of tokens
    function pay(address user, uint256 reward) internal {

        if (totalSupply() + reward <= MAX_SUPPLY) { // make sure claim does not exceed total supply

            _mint(user, reward); // erc20 mint updates totalSupply

        } else { // supply + rewards > max supply, so give claimer less rewards 
            reward = MAX_SUPPLY - totalSupply();
            _mint(user, reward);
        }

        emit RewardPaid(user, reward);
    }

    // called on transfers, mint, burn by nft contract
	function updateReward(address from, address to) public {
		require(msg.sender == address(NFTContract), "Only SBC contract can call this function");
        uint256 time = block.timestamp;

        // pay out final rewards to previous holder
        if (from != address(0)) { 

            pay(from, getPendingReward(from));

            if (getNFTBalance(from) > 1) { // determine wether NFT sender will have any left after transfer
                lastUpdate[from] = time;
            } else {
                lastUpdate[from] = 0;
            }
            
        }
        // pay out pending rewards to NFT reciever
        if (to != address(0)) { 

            if (lastUpdate[to] > 0) {

                pay(to, getPendingReward(to));
            }
            lastUpdate[to] = time;
        }
	}
}
