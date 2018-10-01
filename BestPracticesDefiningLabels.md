# From classification to labeling roadmap – Chapter 1: Choose your labels 
  
One thing I find intriguing when deploying Azure Information Protection (AIP) with clients, is how much work and effort goes into the process of defining and signing off the label taxonomy. So, I thought I'd share with you some of the advice I give on how to use labels and walk you through some of the guidelines I try to follow in order to create the most effective labeling Taxonomy for the companies I work with. 

We start with information classifications. Almost every company has its own classification system. Information can be classified in many ways, but in the context of AIP which is focused on security classifications, the classifications represent the risk associated with the information, and state the way the information should be used and how it must be protected. AIP is a tool that helps the user apply the policy in a natural and user-friendly way. To demonstrate how we can go from a classification system to an effective labeling system, we will follow the example of a fictional company, Contoso .  

The Contoso classifications standard is a risk-based standard that was defined by L&C and has been in use within the company for a long time. All of the company employees are educated about the different classifications and policy dictates they should classify all documents they produce and mark them accordingly. The levels are called “Level 1”, “Level 2”, and “Level 3” and defined as follows: 

-Level 1: Information owned by or shared with Contoso which has no associated risk but is not for public release. Can be shared with externals parties if necessary for conducting business. 
-Level 2: Information owned by or shared with Contoso which has associated risk. Can be shared with authorized externals parties, only if necessary for conducting business. Must be protected at rest. 
-Level 3: Information owned by or shared with Contoso which has associated risk. Can be shared with authorized externals parties, by authorized employees only, if necessary for conducting business. Must be protected at rest and in transit and shared under usage restrictions. 

When I work with my client, usually I will not challenge their Classification levels. My aim is to help them configure AIP in a way that will reflect the classification standard and help their users embed it into their business process. 

## Name Your Classifications

When creating the AIP taxonomy, you should start by naming your existing classifications. My general recommendations when creating a label name are; be descriptive of the classification, be as short as possible, and imply action. For example, if we look at the Contoso classifications above, the term “Level 1” is not descriptive and implies no action. Being short is not enough. In contrast, “Internal” describes information which is for internal use only, is short (one word), and implies that sharing is not permitted.  However, it does not entirely match the classification which states that sharing IS permitted in some scenarios.  

So, let's convert Contoso's classification description into a Taxonomy: 

I chose "General" for the basic "Level1", as most of the information in an organization would fall under this category. General implies common use data. General also implies the adherence to a normal standard of conduct which fits well for this case.  For "Level2",

I chose "Confidential" to imply a more restrictive nature of use and sharing based on confidence in a trusted users group. Adopting the same logic, for “Level3”, I chose “Highly Confidential” which implies further restrictions on data with a higher sensitivity level. 
  
Level 1 - General
Information owned by or shared with Contoso which has no associated risk but is not for public release. Can be shared with externals parties if necessary for conducting business. 

Level 2 - Confidential 
Information owned by or shared with Contoso which has associated risk. Can be shared with authorized externals parties, only if necessary for conducting business must be protected at rest. 

Level 3 - Highly Confidential
Information owned by or shared with Contoso which has associated risk. Can be shared with authorized externals parties, by authorized employees only, if necessary for conducting business. must be protected at rest and in transit and share under usage restrictions 
 
Here's an example of how the labels schema translates to the AIP UI (these are going to be visible to all employees and the basis of the global policy of AIP). 

**Screenshot** 

## Cover the Usability Gaps.  

In any risk-based classification system, you may find what can be called usability gaps. I always try to think how users are going to use the labels. My goals are to make it easy for them to make the decision of which label to use. I want to avoid cases of users choosing not to classify, or over classifying because they feel their information does not fall under one of the labels in the taxonomy. 

For example: 

Information which is not related to any business activity therefor falls under no defined risk category (Invitations to a team event, or a grocery list. These would be categorized as non-business. Another use case is information which was cleared for release as information you can share freely with anyone, be it inside or outside the company. The most common term we find in use is "Public".  in some cases, a single classification level might have two different use cases. For instance, a highly confidential document might have different restrictions associated with it when shared with different audiences. An example of this would be having a different policy for highly confidential information shared with internals users only versus information shared with external parties. If we apply these additional considerations to our Taxonomy, we get: 

>
|Contoso Original Classification|Description|Label Taxonomy|
|:------------------------------|:----------|:-------------|
|N/A|Information not related to the Business and do not bare risk to the company|Non-Business|
|N/A|Information which has no risk attached to it and was authorized for sharing without restrictions with internals or externals|Public|
|Level 1|Information owned by or shared with Contoso which has no associated risk but is not for public release. Can be shared with externals parties if necessary for conducting business.|General|
|Level 2|Information owned by or shared with Contoso which has associated risk. Can be shared with authorized externals parties, only if necessary for conducting business must be protected at rest.|Confidential|
|Level 3|Information owned by or shared with Contoso which has associated risk. Can be shared with authorized externals parties, by authorized employees only, if necessary for conducting business. must be protected at rest and in transit and cannot be shared with external.|Highly Confidential (Internal Only)|
|Level 3|Information owned by or shared with Contoso which has associated risk. Can be shared with authorized externals parties, by authorized employees only, if necessary for conducting business. must be protected at rest and in transit and share under usage restrictions|Highly Confidential (Secure Sharing) |
   
Here a look of how the extended labels schema translate to the AIP UI, notice the "Highly Confidential" two sublabels (These labels are configured in the global policy and visible to all employees as).  

 
 
##Specific Taxonomies for Selected Groups

In some companies there are divisions or departments that have additional classifications or special use cases that are not covered by the general taxonomy. These can be configured by adding scoped policies.  For example, Contoso HR are using two internal classifications that correspond with Level2 and Level3 as shown below: 

**TABLE**
 
While the HR specific labels are used only by HR personnel, HR personnel are also required to use the company-wide labels.  Combining both policies, we get the policy for HR employees looks like: 

**TABLE**

Information owned by or shared with Contoso by employees or Candidates which has associated risk. Can be shared with authorized externals parties, only if necessary for conducting business must be protected at rest. 
  
**TABLE**

Here's a look of how the extended labels schema looks in the AIP UI, showing "Highly Confidential" with the added HR specific labels (visible to HR employees only). 

**SCREENSHOT**
 
Here's a look of how the extended labels schema looks on the AIP UI with the Confidential" additional HR label sublabels (Visible to HR employees only). 

**SCREENSHOT**

## Sign-off on Your Taxonomy

Whatever taxonomy you end up with, you need to get the approval of your business stake holders. Legal, compliance, and security departments will have viable input. They'll also have specific use cases to cover that require the use of additional scoped policies. I would suggest you gather these requirements and compile a proposal for a labeling schema you can then present back to your stake holders.   

While it is important that you set up all the scoped policies you need to meet business requirements, keep in mind that this can get out of hand if you let it.  Remember that scoped policies should not be used as a replacement for NTFS or File Share permissions and should be targeting the groups that have access to the data rather than the groups that are protecting the data.  For example, you can use an Internal Use label for multiple groups and then secure need to know via NTFS or File Share permissions the same way you are today.  This lowers your risk of information disclosure significantly while keeping your scoped policies to a minimum. 

## Summary and Next Steps 

The basic steps to convert your classifications to an AIP labels schema are 

-Start with your risk-based classifications 
-Build the appropriate Taxonomy around it  
-Cover any "Usability Gaps" you Identify 
-Cover any department specific classifications 
-Formulate a proposal to bring back to your stake holders  

After you deploy the first version your Taxonomy you can test how it fits your requirements. You can then add more labels to cover use cases you were not aware of by applying more scoped policies as needed. You can also modify specific labels and their descriptions if you find that the terminology does not fit your assumptions, or if it creates confusion for your users.   

If you deployed labels as the first phase of your deployment, you can start planning and deploying a protection scheme to enforce restrictions based on your company policy. In a future post we'll discuss how to configure advanced classification properties, configure a default label, use recommendations, and apply labels automatically. 

## Related reading