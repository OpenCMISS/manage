# If you set a github username, cmake will automatically try and locate all the components as repositories under that github account.
SET(GITHUB_USERNAME )

# If enabled, ssl connections like git@github.com/username are used instead of https access.
# Requires public key registration with github but wont require to enter the password every time. 
SET(GITHUB_USE_SSL YES)

#SET(IRON_REPO https://...)
#SET(IRON_BRANCH mybranch)