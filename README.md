# Sign in users and call a protected web API in sample iOS (Swift) mobile app

* [Overview](#overview)
* [Contents](#contents)
* [Prerequisites](#prerequisites)
* [Project setup](#project-setup)
* [Key concepts](#key-concepts)
* [Reporting problems](#reporting-problems)
* [Contributing](#contributing)

## Overview

This guide demonstrates how to configure a sample iOS mobile application to sign in users, and call an ASP.NET Core web API using Microsoft Entra for customers.

## Contents

| File/folder | Description |
|-------------|-------------|
| `MSALiOS/Configuration.swift`       | Configuration file. |
| `.gitignore` | Define what to ignore at commit time. |
| `README.md` | This README file. |
| `LICENSE`   | The license for the sample. |

## Prerequisites

- <a href="https://developer.apple.com/xcode/resources/" target="_blank">Xcode</a>.
- Microsoft Entra External ID for customers tenant. If you don't already have one, <a href="https://aka.ms/ciam-free-trial?wt.mc_id=ciamcustomertenantfreetrial_linkclick_content_cnl" target="_blank">sign up for a free trial</a>. 
- An API registration that exposes at least one scope (delegated permissions) and one app role (application permission) such as *ToDoList.Read*. If you haven't already, follow the instructions for [call an API in a sample iOS mobile app](https://learn.microsoft.com/en-us/entra/external-id/customers/sample-native-authentication-ios-sample-app-call-web-api) to have a functional protected ASP.NET Core web API. Make sure you complete the following steps:

    - Register a web API application.
    - Configure API scopes.
    - Configure app roles.
    - Configure optional claims.
    - Clone or download sample web API.
    - Configure and run sample web API.

## Project setup

To enable your application to authenicate users with Microsoft Entra, Microsoft Entra for customers must be made aware of the application you create. The following steps show you how to:

### Step 1: Register an application

Register your app in the Microsoft Entra admin center using the steps in [Register an application](https://learn.microsoft.com/en-us/entra/external-id/customers/sample-mobile-app-ios-swift-sign-in-call-api#register-an-application).

### Step 2: Add a platform redirect URL

Add platform URL using the steps in [Add a platform redirect URL](https://learn.microsoft.com/en-us/entra/external-id/customers/sample-mobile-app-ios-swift-sign-in-call-api#add-a-platform-redirect-url).

### Step 3: Enable public client flow

Enable public client flow using the steps in [Enable public client flow](https://learn.microsoft.com/en-us/entra/external-id/customers/sample-mobile-app-ios-swift-sign-in-call-api#enable-public-client-flow).

### Step 4: Delegated permission to Microsoft Graph

Grant API permissions using the steps in [Delegated permission to Microsoft Graph](https://learn.microsoft.com/en-us/entra/external-id/customers/sample-mobile-app-ios-swift-sign-in-call-api#delegated-permission-to-microsoft-graph).

### Step 5: Grant web API permissions to the iOS sample app

Grant web API permissions to the iOS sample app using the steps in [Grant web API permissions to the iOS sample app](https://learn.microsoft.com/en-us/entra/external-id/customers/sample-mobile-app-ios-swift-sign-in-call-api#grant-web-api-permissions-to-the-ios-sample-app).

### Step 6: Clone sample iOS mobile application

Clone the sample iOS mobile application by following the steps outlined in [Clone sample iOS mobile application](https://learn.microsoft.com/en-us/entra/external-id/customers/sample-mobile-app-ios-swift-sign-in-call-api#clone-sample-ios-mobile-application).

### Step 7: Run and test sample iOS mobile application

Run and test the iOS sample mobile application by following the steps in [Run and test sample iOS mobile application](https://learn.microsoft.com/en-us/entra/external-id/customers/sample-mobile-app-ios-swift-sign-in-call-api#run-ios-sample-app-and-call-web-api).

## Key concepts

Open `MSALiOS/Configuration.swift` file and you find the following configurations:

```swift
import Foundation

@objcMembers
class Configuration: NSObject {
    static let kTenantSubdomain = "Enter_the_Tenant_Subdomain_Here"
    
    // Update the below to your client ID you received in the portal.
    static let kClientID = "Enter_the_Application_Id_Here"
    static let kRedirectUri = "Enter_the_Redirect_URI_Here"
    static let kProtectedAPIEndpoint = "Enter_the_Protected_API_Full_URL_Here"
    static let kScopes: [String] = ["Enter_the_Protected_API_Scopes_Here"]
    
    static let kAuthority = "https://\(kTenantSubdomain).ciamlogin.com"

}
```

The Swift configuration file has:

- `Enter_the_Application_Id_Here` is replaced with the **Application (client) ID** of the app you registered earlier.
- `Enter_the_Redirect_URI_Here` is replaced with the value of *kRedirectUri* in the Microsoft Authentication Library (MSAL) configuration file you downloaded earlier when you added the platform redirect URL.
- `Enter_the_Protected_API_Full_URL_Here` is replaced with the URL to your web API. The *Enter_the_Protected_API_Full_URL_Here* should include the base URL (the deployed web API URL) and the endpoint (/api/todolist) for our ASP.NET web API.
- `Enter_the_Protected_API_Scopes_Here` is replaced with the scopes recorded in [Grant web API permissions to the iOS sample app](#grant-web-api-permissions-to-the-ios-sample-app).
- `Enter_the_Tenant_Subdomain_Here` and replace it with the Directory (tenant) subdomain. For example, if your tenant primary domain is `contoso.onmicrosoft.com`, use `contoso`. If you don't know your tenant subdomain, learn how to [read your tenant details](https://learn.microsoft.com/en-us/entra/external-id/customers/how-to-create-customer-tenant-portal#get-the-customer-tenant-details).

You use `MSALiOS/Configuration.swift` file to set configuration options when you initialize the client app in the Microsoft Authentication Library (MSAL).

## Reporting problems

* Search the [GitHub issues](https://github.com/Azure-Samples/ms-identity-ciam-browser-delegated-ios-sample/issues) in the repository - your problem might already have been reported or have an answer.
* Nothing similar? [Open an issue](https://github.com/Azure-Samples/ms-identity-ciam-browser-delegated-ios-sample/issues/new) that clearly explains the problem you're having running the sample app.

## Contributing

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information, see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
