# acl_finder

Just a simple tool I wrote to enumerate all ACLs in a domain. The goal here is to make it possible to search across the collection and allow to find interesting rights to abuse.

**Requirements:**
- Impacket
- ldapsearch

**Usage:**
- First, modify the variables at the top of the file accordingly to your environment and the credentials you have;
- Then you can just go ahead and run `bash search_acls.sh`, and the tool will collect and save all ACLs in a separate directory;
- Finally, you can grep for your user across the collection and check interesting rights!

**Example search:**
Let's assume I have the credentials for the stannis.baratheon user. First step will be to modify the variables:

![image](https://github.com/user-attachments/assets/9e130d3a-ade2-49c1-b62b-165f3330f6fa)

Then, I can go ahead and just run the script to start collecting the ACLs for the target domain I specified in the BASE_DN variable:

![image](https://github.com/user-attachments/assets/280f515e-c7d9-4286-b4de-17f951c1c354)

And finally, I can go ahead and grep for the user I control across the entire collection:

```bash
grep -C10 -r "stannis" ./acl_collection
```

In this case I can see that he has GenericAll rights over the `KINGSLANDING$` machine (the name of the file):

![image](https://github.com/user-attachments/assets/611087f7-4ecd-4019-88a5-68d24364bfeb)

Fun thing is that this works for everything... I see that the user samwell.tarly can write over a GPO for example:

![image](https://github.com/user-attachments/assets/7ee534e2-91a0-4d7e-93d8-bcbca396e98a)

And I could even search for computers that probably allow some principals to read the LAPS password, by searching for ACEs with `ControlAccess` in the Access mask and Unknonw in the Object Type GUID:

```bash
grep -C10 -ri "Unknown" ./acl_collection | grep '$.acl' | grep -C10 -i "ControlAccess"
```

![image](https://github.com/user-attachments/assets/5ae38c6a-201c-4932-9f88-8edd1acc41b1)


You get the picture. For more about what to search and how each right works check out my article:

- https://iuribpmoro.com/posts/adhacking-0x06-abusing-acls/
