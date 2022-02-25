// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract InkToken is ERC20, Ownable, Pausable {

    //TODO uint256 constant public MAX_SUPPLY = 132407400 ether; 
	uint256 constant public INTERVAL = 86400; 
    uint256 constant public NFTReward = 5 ether;

	mapping(address => uint256) private lastUpdate; // record when user interacts with contract

	IERC721Enumerable public NFTContract;  

	event RewardPaid(address indexed user, uint256 reward); 
 
    constructor(address NFTContractAddress) ERC20("Sad Bears Club Ink", "INK") {

        NFTContract = IERC721Enumerable(NFTContractAddress);
        pause();
    }

    /* * * * * * * * * * * * * * * OWNER ONLY FUNCTIONS * * * * * * * * * * * * * * */

    // stop users from interacting with the contract
    function pause() public onlyOwner { 

        _pause(); 
    }

    // allow users to interact with contract
    function unpause() public onlyOwner { 

        _unpause(); 
    } 

    /* * * * * * * * * * * * * * * GASLESS GET FUNCTIONS * * * * * * * * * * * * * * */

    // returns the last timestamp user interacted with the contract
    // needs to be non zero in order to claimReward (call startEarningRent)
    function getLastUpdate(address user) external view returns(uint256) {
        
        return lastUpdate[user];
    }

    // return the number of SBC NFTs user owns
    function getNFTBalance(address user) public view returns (uint256) {

        return NFTContract.balanceOf(user);
    }

    // returns the SBC NFT token IDs user owns
    function getNFTIds(address user) public view returns (uint256[] memory _tokensOfOwner) {
        _tokensOfOwner = new uint256[](getNFTBalance(user));

        for (uint256 i = 0; i < getNFTBalance(user); i++) { 
            _tokensOfOwner[i] = NFTContract.tokenOfOwnerByIndex(user, i);
        }
    }
    
    // DID
    function getPendingReward(address user) public view returns(uint256) { 
        // (block.timestamp - lastUpdate[user]) / INTERVAL = number of days
        // NFTReward = sum of each NFT daily reward
        // 1 ether = 1000000000000000000
        return NFTContract.balanceOf(user) * (NFTReward * 1 ether * (block.timestamp - lastUpdate[user])) / INTERVAL;
    }

    /* * * * * * * * * * * * * * * USER GAS FUNCTIONS * * * * * * * * * * * * * * */

    // called on transfers AND mint
	function updateReward(address from, address to) external whenNotPaused {
		require(msg.sender == address(NFTContract));
        uint256 time = block.timestamp;
        uint256 senderLastUpdate = lastUpdate[from];

        // pay out final rewards to previous holder
        if (from != address(0)) { 

            pay(from, getPendingReward(from));
            lastUpdate[from] = time;
        }
        // pay out pending rewards to NFT reciever
        if (to != address(0)) { 

            if (lastUpdate[to] > 0) {

                pay(to, getPendingReward(to));
            }
            lastUpdate[to] = time;
        }
	}

    // DID
    function claimReward() external whenNotPaused { 
        require(totalSupply() < MAX_SUPPLY, "INK collection is over"); // INK earned will not be claimable after max INK has been minted
        
        // we don't need this right? don't want to remove until this is confirmed
        // require(lastUpdate[msg.sender] != 0, "If you have a LAND token, call startEarningRent"); 
 
        uint256 currentReward = getPendingReward(msg.sender);

        pay(msg.sender, currentReward);

        lastUpdate[msg.sender] = block.timestamp; 
    }

    /* * * * * * * * * * * * * * * INTERNAL HELPER FUNCTIONS * * * * * * * * * * * * * * */
    
    // mints the user appropriate amount of tokens
    function pay(address user, uint256 reward) internal whenNotPaused {

        if (totalSupply() + reward <= MAX_SUPPLY) { // make sure claim does not exceed total supply

            _mint(user, reward); // erc20 mint updates totalSupply

        } else { // supply + rewards > max supply, so give claimer less rewards 
            reward = MAX_SUPPLY - totalSupply();
            _mint(user, reward);
        }

        emit RewardPaid(user, reward);
    }
}
