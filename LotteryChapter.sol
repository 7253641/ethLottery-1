pragma solidity ^0.4.20;

contract LotteryChapter{
    
    struct LotteryDetail{
        address buyer;
        uint256 noteNumber;
    }
    
    struct NoteDetail{
        LotteryDetail[] lotteryDetail;
        uint256 noteCount;
    }
    
    mapping(bytes32=>NoteDetail) private lotteryMap;
    
    mapping(address=>uint256) private awardDetail;
    
    uint256 private chapter;
    
    string private chapterSponsor;
    
    int8[] private lotteryNumbers;
    
    uint256 private startTime;
    
    bool private finishStatus;
    
    address[] private runLotteryAddress;
    
    uint256 private bonus;
    
    address private owner;
    
    modifier isOwner(){
        if(msg.sender!=owner){
            revert();
        }
        _;
    }
    
    function getLotteryLength() constant public returns (uint256){
        return lotteryNumbers.length;
    }
    
    function LotteryChapter(uint256 _startTime,uint256 _chapter,string _chapterSponsor) public{
        owner = msg.sender;
        startTime = _startTime;
        chapter = _chapter;
        chapterSponsor = _chapterSponsor;
        finishStatus = false;
    }
    
    function addLottery(int8[] note,address buyer,uint256 noteNumeber) public isOwner{
        if(finishStatus){
            revert();
        }
        LotteryDetail memory lottery = LotteryDetail(buyer,noteNumeber);
        NoteDetail storage noterDetail = lotteryMap[keccak256(note)];
        noterDetail.lotteryDetail.push(lottery);
        noterDetail.noteCount += noteNumeber;
    }
    
    function addLotteryNumber(int8 number,address runAddress) public isOwner{
        finishStatus = true;
        lotteryNumbers.push(number);
        runLotteryAddress.push(runAddress);
    }
    
    function getAward() public{
        uint256 awardBonus = awardDetail[msg.sender];
        if(awardBonus>0){
            msg.sender.transfer(awardBonus);
            awardDetail[msg.sender] = 0;
        }
    }
    
    function calculateAward(uint256 balance) public isOwner returns (uint256){
        //一等奖判定
        firstPrice(balance);
        //二等奖判定
        secondPrice(balance);
        //三等奖判定
   
        //给开奖地址发奖
        for(uint i=0;i<6;i++){
            awardDetail[runLotteryAddress[i]]+= balance*2/1000;
        }
        awardDetail[runLotteryAddress[6]]+= balance*1/100;
        bonus+=balance*22/1000;
    }
    
    function firstPrice(uint256 balance) internal{
        NoteDetail memory awardNote = lotteryMap[keccak256(lotteryNumbers)];
        uint256 noteCount = awardNote.noteCount;
        if(noteCount==0){
            return;
        }
        uint256 firstBonus = balance * 6 / 10;
        bonus+= firstBonus;
        LotteryDetail[] memory lotterys = awardNote.lotteryDetail;
        uint256 noteBonus = firstBonus / noteCount;
        for(uint i=0;i<lotterys.length;i++){
            awardDetail[lotterys[i].buyer] += lotterys[i].noteNumber*noteBonus;
        }
    }
    
    function secondPrice(uint256 balance) internal{
        LotteryDetail[] storage secondLotterys;
        int8[] memory secondNumbers = lotteryNumbers; 
        uint256 noteCount = 0;
        for(int8 i = 1;i<34&&i!=lotteryNumbers[6];i++){
            secondNumbers[6]=i;
            NoteDetail memory awardNote = lotteryMap[keccak256(lotteryNumbers)];
            LotteryDetail[] memory changeAddress = awardNote.lotteryDetail;
            noteCount +=awardNote.noteCount;
            for(uint j=0;j<changeAddress.length;j++){
                secondLotterys.push(changeAddress[j]);
            }
        }
        if(noteCount==0){
            return;
        }
        uint256 secondBonus = balance * 2 / 10;
        bonus+= secondBonus;
        uint256 noteBonus = secondBonus / noteCount;
        for(uint256 k=0;k<secondLotterys.length;k++){
            awardDetail[secondLotterys[k].buyer] += secondLotterys[k].noteNumber*noteBonus;
        }
    }
    
    function thirdPrice(uint256 balance) internal{
        LotteryDetail[] storage secondLotterys;
        int8[] memory secondNumbers = lotteryNumbers; 
        uint256 noteCount = 0;
        for(int8 i = 1;i<34&&i!=lotteryNumbers[6];i++){
            secondNumbers[6]=i;
            NoteDetail memory awardNote = lotteryMap[keccak256(lotteryNumbers)];
            LotteryDetail[] memory changeAddress = awardNote.lotteryDetail;
            noteCount +=awardNote.noteCount;
            for(uint j=0;j<changeAddress.length;j++){
                secondLotterys.push(changeAddress[j]);
            }
        }
        if(noteCount==0){
            return;
        }
        uint256 secondBonus = balance * 2 / 10;
        bonus+= secondBonus;
        uint256 noteBonus = secondBonus / noteCount;
        for(uint256 k=0;k<secondLotterys.length;k++){
            awardDetail[secondLotterys[k].buyer] += secondLotterys[k].noteNumber*noteBonus;
        }
    }
     
}