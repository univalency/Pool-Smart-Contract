// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */
contract RandomNumberConsumer is VRFConsumerBase {
    
    //original variables
    uint256 public liquidityCap;

    uint256 private _totalSupply;

    address public reserveRegistry;

    address internal _token = 0x0fC5025C764cE34df352757e82f7B5c4Df39A836;

    address depositReserve = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    
    
    //new variables (LINK randomness and other)
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomResult;
    
    uint128 public participantCount;
    uint256 public rewardAmount;
    
    //record addresses of pool participants
    mapping(uint => address payable) poolmemberId;
    mapping(address => uint) amountsDeposited;
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor() 
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }
   
        

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }
    
    
    function depositToPool(address payable depositor) public payable {
        require(msg.value > 0, "You must send in some ether to join the pool");
        poolmemberId[participantCount] = depositor;
        participantCount += 1;
        amountsDeposited[depositor] += msg.value;
        payable(depositReserve).transfer(msg.value);
    }
    
    //calling ChainLink's RNG function and dividing modulo pool size
    function determineWinner() public returns(uint) {
        getRandomNumber();
        uint winner = randomResult % participantCount;
        return winner;
    }
    
    //trabsfer reward amount to the winner aaddress
    function rewardWinner() public payable {
        poolmemberId[determineWinner()].transfer(rewardAmount);
    }
    
    //return tokens to all participants
    function _redeem() public payable {
        for (uint i=0; i <= participantCount; i++) {
            poolmemberId[i].transfer(amountsDeposited[poolmemberId[i]]);
        }
    }
    
