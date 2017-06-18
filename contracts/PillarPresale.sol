pragma solidity ^0.4.11;

import './zeppelin/SafeMath.sol';
import './zeppelin/ownership/Ownable.sol';
import './zeppelin/lifecycle/Pausable.sol';
import './PillarToken.sol';
import './IcedStorage.sol';

contract PillarPresale is Pausable {
  using SafeMath for uint;
  uint public constant totalSupply = 16000000;
  address pillarTokenFactory;
  uint totalUsedTokens;
  mapping(address => uint) balances;
  //Sale Period
  address[] purchasers;
  uint public salePeriod;

  uint startBlock;
  uint endBlock;

  // flags whether ICO is afoot.
  bool fundingMode = true;

  //price will be in finney
  uint constant PRESALE_PRICE = 1 finney;

  PillarToken public plr;
  IcedStorage public plWallet;

  modifier isFundable() {
      if (!fundingMode) throw;
      _;
  }

  function PillarPresale(address _pillarTokenFactory,uint _startBlock,uint _endBlock) {
    //presale is open for
    salePeriod = now.add(60 hours);
    startBlock = _startBlock;
    endBlock = _endBlock;
    pillarTokenFactory = _pillarTokenFactory;
    totalUsedTokens = 0;
  }

  function () external isFundable payable {
    if(now > salePeriod) throw;
    if(block.number < startBlock) throw;
    if(block.number > endBlock) throw;
    if(totalUsedTokens >= totalSupply) throw;
    if(msg.value == 0) throw;

    uint numTokens = msg.value.div(PRESALE_PRICE);
    totalUsedTokens = totalUsedTokens.add(numTokens);
    if (totalUsedTokens > totalSupply) throw;

    purchasers.push(msg.sender);
    balances[msg.sender] = balances[msg.sender].add(numTokens);
  }

  function finalize() external onlyOwner {
    if(!fundingMode) throw;

    if((block.number <= startBlock || block.number >= endBlock)) throw;

    if(address(plWallet) == address(0)) throw;

    if(address(plr) == address(0)) throw;

    //migrate the ether to the pillarTokenFactory wallet
    if(!pillarTokenFactory.send(this.balance)) throw;

    //move the unsold tokens to a multisig wallet
    uint remain = totalSupply.sub(totalUsedTokens);
    if(remain > 0) {
      plr.allocateTokens(address(plWallet),remain);
    }
  }

  function balanceOf(address owner) returns (uint) {
    return balances[owner];
  }

  function getPurchasers() external returns (address[]) {
    return purchasers;
  }

  function numOfPurchasers() external returns (uint) {
    return purchasers.length;
  }
}