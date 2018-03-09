pragma solidity ^0.4.20;

import "./LotteryConvert.sol";

import "./LotteryChapter.sol";

contract EthLottery {
    
    struct Sponor{
        string sponorDiscription;
        uint256 sponorNumber;
    }

    LotteryChapter[] private lotteryChapters;
    
    bool private isRunLottery;
   
    Sponor[] private sponors;
    
    uint256 private lastStartTime;
    
    uint256 private intervalTime;
    
    uint256 private notePrice;
    
    uint256 private currentChapter;
    
    modifier isLotteryCorrect(int8[] lotteryNumber,uint256 noteNumber){
        if(isRunLottery){
            revert();
        }
        for(uint i=0;i<lotteryNumber.length;i++){
            if(lotteryNumber[i]<1||lotteryNumber[i]>33){
                revert();
            }
        }
        uint256 overValue = msg.value-noteNumber*notePrice;
        if(overValue<0){
            revert();
        }
        
        if(overValue>0){
            msg.sender.transfer(overValue);
        }
        _;
    }
    
    modifier canRun(){
        if(lastStartTime+intervalTime<now){
            revert();
        }
        _;
    }
    
    function EthLottery(uint256 _lastStartTime,uint256 _intervalTime,uint256 _notePrice) public{
        lastStartTime = _lastStartTime;
        intervalTime = _intervalTime;
        notePrice = _notePrice;
        currentChapter = 1;
        isRunLottery = false;
        lotteryChapters.push(new LotteryChapter(lastStartTime,1,""));
    }
    
    function buyLottery(int8[] lotteryNumber,uint256 noteNumber) payable isLotteryCorrect(lotteryNumber,noteNumber) public{
        lotteryChapters[currentChapter].addLottery(lotteryNumber,msg.sender,noteNumber);
    }
    
    function runLottery() canRun public{
        LotteryChapter nowChapter = lotteryChapters[currentChapter];
        uint256 lotteryLength=nowChapter.getLotteryLength();
        if(lotteryLength>6){
            revert();
        }
        int8 number = int8(now%33);
        nowChapter.addLotteryNumber(number,msg.sender);
        if(lotteryLength!=6){
            return;
        }
    }
}
