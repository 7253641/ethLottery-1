pragma solidity ^0.4.20;


contract LotteryConvert {
    address private owner;
    
    modifier isOwner(address sender){
        if(sender!=owner){
            throw;
        }
        _;
    }
    
    function LotteryConvert() payable{
        owner = msg.sender;
    }
    
    function getAward(address awardAddress,uint bonus) public isOwner(msg.sender){
        awardAddress.transfer(bonus);
    }
}
