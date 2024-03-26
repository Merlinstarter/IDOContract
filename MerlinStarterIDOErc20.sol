// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10 <0.8.19;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}



contract MerlinStarterIDO is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    IERC20 public oriToken;
    IERC20 public rewardToken;

    uint256 public joinIdoPrice=16*10**14;
    uint256 public rewardAmount=80000*10**18;
    uint256 private _MaxCount=100;

    bool public mbStart=false;
    uint256 public startTime=0;
    uint256 public dt=60*60;
    uint256 public chaimDt1=0;
    uint256 public chaimDt2=0;
    uint256 public chaimDt3=0;
    

    mapping (address => bool) private _Is_WhiteAddrArr;
    address[] private _WhiteAddrArr;
    mapping (address => bool) private _bAlreadyJoinIdoArr;
    mapping (address => uint256) private _alreadyChaimNumArr;

    struct sJoinIdoPropertys {
        address addr;
        uint256 joinIdoAmount;
        uint256 time;
    }
    mapping(uint256 => sJoinIdoPropertys) private _joinIdoPropertys;
    uint256 private _sumCount;

    event JoinIdoCoins(address indexed user, uint256 amount,uint256 id);
   address public mFundAddress = 0x2EDDE6f6ec946CAbF1DC356cB88dE7589486B852;

    constructor(){
        chaimDt1=dt + 24*3600+ 3600;
        chaimDt2=chaimDt1 + 30*24*3600;
        chaimDt3=chaimDt1+ 60*24*3600;

        oriToken = IERC20(0x1F113afE40bfCb3D208Bb2F0B941008463A1101A);
        rewardToken = IERC20(0x16F91ec24A9AED8e7557d0D7CC25c576D562ef07);
        mFundAddress = 0x2EDDE6f6ec946CAbF1DC356cB88dE7589486B852;
    }
    
    /* ========== VIEWS ========== */
    function maxCount() external view returns(uint256){
        return _MaxCount;
    }
    function sumCount() external view returns(uint256){
        return _sumCount;
    }
    function isAlreadyEnd() external view returns(bool){
        if(!mbStart) return false;
        if(block.timestamp<startTime+dt) return false;
        return true;
    }
    //read info
    function joinIdoInfo(uint256 iD) external view returns (
        address addr,
        uint256 joinIdoAmount,
        uint256 time
        ) {
        require(iD <= _sumCount, "MerlinStarterIDO: exist num!");
        addr = _joinIdoPropertys[iD].addr;
        joinIdoAmount = _joinIdoPropertys[iD].joinIdoAmount;
        time = _joinIdoPropertys[iD].time;
        return (addr,joinIdoAmount,time);
    }

    function joinIdoInfos(uint256 fromId,uint256 toId) external view returns (
        address[] memory addrArr,
        uint256[] memory joinIdoAmountArr,
        uint256[] memory timeArr
        ) {
        require(toId <= _sumCount, "MerlinStarterIDO: exist num!");
        require(fromId <= toId, "MerlinStarterIDO: exist num!");
        addrArr = new address[](toId-fromId+1);
        joinIdoAmountArr = new uint256[](toId-fromId+1);
        timeArr = new uint256[](toId-fromId+1);
        uint256 i=0;
        for(uint256 ith=fromId; ith<=toId; ith++) {
            addrArr[i] = _joinIdoPropertys[ith].addr;
            joinIdoAmountArr[i] = _joinIdoPropertys[ith].joinIdoAmount;
            timeArr[i] = _joinIdoPropertys[ith].time;
            i = i+1;
        }
        return (addrArr,joinIdoAmountArr,timeArr);
    }
    
    function isWhiteAddr(address account) public view returns (bool) {
        return _Is_WhiteAddrArr[account];
    }
    function isAlreadyJoinIdoAddr(address account) public view returns (bool) {
        return _bAlreadyJoinIdoArr[account];
    }
    function alreadyChaimNum(address account) public view returns (uint256) {
        return _alreadyChaimNumArr[account];
    }
    function getWhiteAccountNum() public view returns (uint256){
        return _WhiteAddrArr.length;
    }
    function getWhiteAccountIth(uint256 ith) public view returns (address WhiteAddress){
        require(ith <_WhiteAddrArr.length, "MerlinStarterIDO: not in White Adress");
        return _WhiteAddrArr[ith];
    }
    function getParameters(address account) public view returns (uint256[] memory){
        uint256[] memory paraList = new uint256[](uint256(8));
        paraList[0]=0; if(mbStart) paraList[0]=1;
        paraList[1]=startTime;
        paraList[2]=0; if(_Is_WhiteAddrArr[account]) paraList[2]=1;
        paraList[3]=0; if(_bAlreadyJoinIdoArr[account]) paraList[3]=1;

        uint256 coe=0;
        if(block.timestamp>startTime+chaimDt1){
            if(_alreadyChaimNumArr[account]<1)coe = 30;
        }

        if(block.timestamp>startTime+chaimDt2){
            if(_alreadyChaimNumArr[account]<2)coe = coe+30;
        }
        if(block.timestamp>startTime+chaimDt3){
            if(_alreadyChaimNumArr[account]<3) coe = coe+40;
        }
        paraList[4]=coe;//can claim ratio
        paraList[5]=rewardAmount.mul(coe).div(100);//can claim amount

        uint256 LastCoe=0;
        if(_alreadyChaimNumArr[account]<1) LastCoe = 30;
        if(_alreadyChaimNumArr[account]<2) LastCoe = LastCoe+30;
        if(_alreadyChaimNumArr[account]<3) LastCoe = LastCoe+40;
        paraList[6]=LastCoe;//last claim ratio
        paraList[7]=rewardAmount.mul(LastCoe).div(100);//last claim amount
        return paraList;
    }
    //---write---//
    function joinIdo() external nonReentrant {
        require(mbStart, "MerlinStarterIDO: not Start!");
        require(block.timestamp<startTime+dt, "MerlinStarterIDO: already end!");
        require(_sumCount<_MaxCount, "MerlinStarterIDO: already end!");
        require(_Is_WhiteAddrArr[_msgSender()], "MerlinStarterIDO:Account  not in white list");
        require(!_bAlreadyJoinIdoArr[_msgSender()], "MerlinStarterIDO: already joinIdo!");

        oriToken.safeTransferFrom(_msgSender(),address(this), joinIdoPrice);

        _bAlreadyJoinIdoArr[_msgSender()]=true;

        _sumCount = _sumCount.add(1);
        _joinIdoPropertys[_sumCount].addr = _msgSender();
        _joinIdoPropertys[_sumCount].joinIdoAmount = joinIdoPrice;
        _joinIdoPropertys[_sumCount].time = block.timestamp;

        emit JoinIdoCoins(msg.sender, joinIdoPrice, _sumCount);
    }
    function claimToken() external nonReentrant{
        require(mbStart, "MerlinStarterIDO: not Start!");
        require(block.timestamp>startTime+dt, "MerlinStarterIDO: need ido end!");
        require(_Is_WhiteAddrArr[_msgSender()], "MerlinStarterIDO:Account  not in white list");
        require(_bAlreadyJoinIdoArr[_msgSender()], "MerlinStarterIDO: not joinIdo!");
        require(block.timestamp>startTime+chaimDt1, "MerlinStarterIDO: need begin claim!");
        require(_alreadyChaimNumArr[_msgSender()]<3, "MerlinStarterIDO: already claim all!");

        uint256 coe=0;
        if(_alreadyChaimNumArr[_msgSender()]<1){
            coe = 30;
            _alreadyChaimNumArr[_msgSender()]=_alreadyChaimNumArr[_msgSender()]+1;
        }
        if(block.timestamp>startTime+chaimDt2){
            if(_alreadyChaimNumArr[_msgSender()]<2){
                coe = coe+30;
                _alreadyChaimNumArr[_msgSender()]=_alreadyChaimNumArr[_msgSender()]+1;
            }
        }
        if(block.timestamp>startTime+chaimDt3){
            if(_alreadyChaimNumArr[_msgSender()]<3){
                coe = coe+40;
                _alreadyChaimNumArr[_msgSender()]=_alreadyChaimNumArr[_msgSender()]+1;
            }
        }
        require(coe>0, "MerlinStarterIDO: claim 0!");
        uint256 amount = rewardAmount.mul(coe).div(100);
        rewardToken.safeTransfer(_msgSender(), amount);
    }
    //---write onlyOwner---//
   function setParameters(address oriTokenAddr,address rewardTokenAddr,
      uint256 joinIdoPrice0,uint256 maxCount0,uint256 rewardAmount0
   ) external onlyOwner {
        require(!mbStart, "MerlinStarterIDO: already Start!");
        oriToken = IERC20(oriTokenAddr);
        rewardToken = IERC20(rewardTokenAddr);
        joinIdoPrice=joinIdoPrice0;
        _MaxCount=maxCount0;
        rewardAmount=rewardAmount0;
    }
    function setStartAlpha(bool bstart) external onlyOwner{
        mbStart = bstart;
        startTime = block.timestamp;
    }
    function setStartStageBeta(bool bstart,address payable stage1Addr) external onlyOwner{
        MerlinStarterIDO tokenA = MerlinStarterIDO(stage1Addr);
        bool bEnd = tokenA.isAlreadyEnd();
        require(bEnd, "MerlinStarterIDO: need stage Alpha end!");
        mbStart = bstart;
        startTime = block.timestamp;
        _MaxCount = _MaxCount + tokenA.maxCount()-tokenA.sumCount();
    }
    function setDt(uint256 tDt,uint256 tDt1,uint256 tDt2,uint256 tDt3) external onlyOwner{
        dt = tDt;
        chaimDt1 = tDt1;
        chaimDt2 = tDt2;
        chaimDt3 = tDt3;
    }
 
    receive() external payable {}
    function withdraw(uint256 amount) external onlyOwner{
        (bool success, ) = payable(mFundAddress).call{value: amount}("");
        require(success, "Low-level call failed");
    }
    function withdrawToken(address tokenAddr,uint256 amount) external onlyOwner{ 
        IERC20 token = IERC20(tokenAddr);
        token.safeTransfer(mFundAddress, amount);
    }

    function addWhiteAccount(address account) external onlyOwner{
        require(!_Is_WhiteAddrArr[account], "MerlinStarterIDO:Account is already in White list");
        _Is_WhiteAddrArr[account] = true;
        _WhiteAddrArr.push(account);
    }
    function addWhiteAccount(address[] calldata  accountArr) external onlyOwner{
        for(uint256 i=0; i<accountArr.length; ++i) {
            require(!_Is_WhiteAddrArr[accountArr[i]], "MerlinStarterIDO:Account is already in White list");
            _Is_WhiteAddrArr[accountArr[i]] = true;
            _WhiteAddrArr.push(accountArr[i]);     
        }
    }
    function removeWhiteAccount(address account) external onlyOwner{
        require(_Is_WhiteAddrArr[account], "MerlinStarterIDO:Account is already out White list");
        for (uint256 i = 0; i < _WhiteAddrArr.length; i++){
            if (_WhiteAddrArr[i] == account){
                _WhiteAddrArr[i] = _WhiteAddrArr[_WhiteAddrArr.length - 1];
                _WhiteAddrArr.pop();
                _Is_WhiteAddrArr[account] = false;
                break;
            }
        }
    }


    
}