pragma solidity ^0.4.20;

import "./LotteryConvert.sol";

import "./LotteryChapter.sol";

contract EthLottery {

    //保存一注彩票对应的地址
    mapping(bytes32 => address[])[100]private numbers;
    //每期中奖地址的奖金
    mapping(address => uint)[100]private awardDetail;
    //总奖金
    uint[] private chapterBonus;
    
    LotteryConvert[] private lotteryConvert;

    //保存上一次开奖开始的时间
    uint private lastStartTime;

    //保存两次开奖之间间隔的时间
    uint private intervalTime;

    //当前开奖的数字
    uint[][] private lotteryNumber;
    
    //当前期数
    uint private chapter;

    //是否正在开奖
    bool private isRunLottery;

    //一注彩票多少钱
    uint private notePrice;

    modifier correctThePay(uint[] param){
        for(uint i=0;i<param.length;i++){
            if(param[i]<1||param[i]>33){
                revert();
            }
        }
        if(param.length!=7){
            revert();
        }
        uint extraWei = msg.value - notePrice;
        //如果合约方法调用时添加的钱不够的话直接返回，超出的话退回超出的量
        if(extraWei<0){
            revert();
        }else if(extraWei>0){
            msg.sender.transfer(extraWei);
        }
        _;
    }

    modifier canRun(){
        //未到开奖时间
        if(now<intervalTime+lastStartTime){
            throw;
        }
        //当期号码已经超过了七个
        if(runLotteryAddress.length>6){
            throw;
        }
        _;
    }

    function EthLottery(uint _lastStartTime,uint _intervalTime,uint _notePrice) payable public{
        lastStartTime = _lastStartTime;
        intervalTime = _intervalTime;
        notePrice = _notePrice;
        uint[] a;
        lotteryNumber.push(a);
        isRunLottery = false;
        chapter=0;
    }
    
    function getNumbers(uint[] note,uint nowChapter) public constant returns (address[]){
        return numbers[nowChapter][keccak256(note)];
    } 
    
    function award(address awardAddress,uint chapter) public constant returns (uint){
        return awardDetail[chapter][awardAddress];
    } 
    
    function getBalance() public constant returns (uint){
        return this.balance;
    }
    
    function getLotteryNumber(uint chapter) public constant returns (uint[]){
        return lotteryNumber[chapter];
    } 

    //购买彩票
    function buyNote(uint[] note) payable correctThePay(note) public{
        if(isRunLottery){
            revert();
        }
        address customer = msg.sender;
        bytes32 key = keccak256(note);
        numbers[chapter][key].push(customer);
    }
    
    //开奖
    function runLottery() canRun public{
        //切换为开奖状态
        isRunLottery = true;
        //新增开奖数字
        lotteryNumber[chapter].push(now%33);
        runLotteryAddress.push(msg.sender);
        //所有数字没有被揭示
        if(runLotteryAddress.length<7){
            return;
        }
        //进入发奖状态
        award();
        //重置下一期开始时间
        chapter+=1;
        lastStartTime += intervalTime;
        //关闭开奖状态
        isRunLottery = false;
        uint[] a;
        lotteryNumber.push(a);
        delete runLotteryAddress;
    }
    
    function getBigAward(uint chapter) public{
        uint awardBonus = awardDetail[chapter][msg.sender];
        if(awardBonus>0){
            lotteryConvert[chapter].getAward(msg.sender,awardBonus);
        }
        awardDetail[chapter][msg.sender]=0;
    }
    
    function getSmallAward(uint chapter,uint[] awardNumber) public{
        uint equalCount=0;
        for(uint j=0;j<awardNumber.length;j++){
            if(awardNumber[j]==lotteryNumber[chapter][j]){
                equalCount+=1;
            }
        }
        uint bonus;
        if(equalCount==5){
            bonus=100;
        }else if(equalCount==4){
            bonus=5;
        }else if(awardNumber[6]==lotteryNumber[chapter][6]){
            bonus=2;
        }
        address[] smallAwardAddress = numbers[chapter][keccak256(awardNumber)];
        address customer = msg.sender;
        uint noteCount = 0;
        for(uint i = 0;i<smallAwardAddress.length;i++){
            if(customer==smallAwardAddress[i]){
                noteCount+=1;
                delete smallAwardAddress[i];
            }
        }
        customer.transfer(bonus*noteCount*notePrice);
    }

    //计算中奖用户
    function award() internal{
        uint balance = this.balance;
        //一等奖判定
        firstPrice(balance);
        //二等奖判定
        secondPrice(balance);
        //三等奖判定
        thirdPrice(balance);
        //给开奖地址发奖
        for(uint i=0;i<6;i++){
            awardDetail[chapter][runLotteryAddress[i]]+= balance*2/1000;
        }
        awardDetail[chapter][runLotteryAddress[6]]+= balance*1/100;
        chapterBonus[chapter]+=balance*22/1000;
        //创建新合约保存当期中奖的奖金给中奖地址领奖
        lotteryConvert[chapter]=(new LotteryConvert).value(chapterBonus[chapter])();
    }
    
    function firstPrice(uint balance) internal{
        address[] memory fp = numbers[chapter][keccak256(lotteryNumber[chapter])];
        uint size = fp.length;
        uint bonus = balance*6/10/size;
        addBonus(fp,bonus,size);
    }
    
    function secondPrice(uint balance) internal{
        uint size=0;
        address[] sp;
        uint[] awardLottery = lotteryNumber[chapter];
        for(uint i = 1;i<=33&&i!=lotteryNumber[chapter][6];i++){
            awardLottery[6]=i;
            address[] memory changeAddress = numbers[chapter][keccak256(awardLottery)];
            for(uint j=0;j<changeAddress.length;j++){
                sp.push(changeAddress[j]);
            }
        }
        uint bonus = balance*2/10/size;
        addBonus(sp,bonus,size);
    }
    
    function thirdPrice(uint balance) internal{
        uint size=0;
        address[] secondPrice;
        for(uint k = 0;k<6;k++){
            uint[] awardLottery = lotteryNumber[chapter];
            for(uint i = 1;i<=33&&i!=lotteryNumber[chapter][k];i++){
                awardLottery[k]=i;
                address[] memory changeAddress = numbers[chapter][keccak256(awardLottery)];
                for(uint j=0;j<changeAddress.length;j++){
                    secondPrice.push(changeAddress[j]);
                }
            }
        }
        uint bonus;
        if(notePrice*1500*size/balance>balance*1/10/size){
            bonus = balance*1/10/size;
        }else{
            bonus = notePrice*1500;
        }
        addBonus(secondPrice,bonus,size);
    }
    
    function addBonus(address[] awardAddress,uint bonus,uint size) internal{
        chapterBonus[chapter]+=bonus*size;
        for(uint i = 0;i<size;i++){
           awardDetail[chapter][awardAddress[i]]+=bonus;
        }
    }
}
