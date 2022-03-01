
async function buttonLogic() {
  const connectButton = document.getElementById("connectButton");
  const pendingRewards = document.getElementById("pendingRewards");
  const claim = document.getElementById("claim");
  
  
  connectButton.innerHTML = "Connecting wallet...";

  let account = null;
  const provider = window.ethereum;

  if (provider == null) {
    connectButton.innerHTML = "Download Metamask to connect your wallet";
  }

  async function checkAccounts() {
    if (provider) {
      const accs = await provider.request({method: 'eth_accounts'});
      return accs[0];
    }
  }

  // check if we've already connected to a wallet
  await checkAccounts()
    .then(acc => account = acc)
    .catch(err => console.err(err)); 

  if (account) {
    connectButton.innerHTML = account.substring(0, 5) + "..." + account.substring(account.length - 4, account.length);
  } else {
    connectButton.innerHTML = "Connect wallet";
  }

  function handleConnectWallet() {
    provider.request({ method: 'eth_requestAccounts' })
      .then(accs => {
        account = accs[0];
        connectButton.innerHTML = account.substring(0, 5) + "..." + account.substring(account.length - 4, account.length);
      })
      .catch(err => connectButton.innerHTML = "Connect metamask wallet"); 
  }

  // PENDING REWARDS HERE
  function displayRewards() {
    contract.methods.getPendingRewards(account).call()
      .then( reward => { 
        console.log("reward: ", reward);
        pendingRewards.innerHTML = reward;
      })
    .catch(err => connectButton.innerHTML = "");
  }

  connectButton.addEventListener('click', _ => {
    if (provider) {
      if (!account) {
        handleConnectWallet();
        displayRewards();
      }
    } else {
      window.location = "https://metamask.io/";
    }
  })
  
  // should be good to go...
  claim.addEventListener('click', _ => {
    if (provider) {
      if (!account) {
        handleConnectWallet();
      } else {
        window.web3 = new Web3(window.ethereum);
        const contract = new window.web3.eth.Contract(ABI, addr);
        
        const transData = {
          gasLimit: 100000, // tweak this number
          from: account,
        }
        
        contract.methods.claimReward().send(transData);
      }
    }
  })

}

buttonLogic();