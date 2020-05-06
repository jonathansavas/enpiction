# enpiction

An app to hide secret information in images.

## Getting Started

For help getting started with Flutter, view the
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Overview

Enpiction is an application to hide secret data which should be
grouped together (such as a website name, username, and password) within 
images on a device. Enpiction operates similar to an encrypted data store by 
encrypting the data prior to storing it. In this case, the data is not stored 
in a centralized, known (to almost any user) location, but rather distributed 
among image files across the device. This technique should also help users 
remember the location of their data by associating data groups with certain 
images. 

## Using the app

#### Choosing images and data to hide

![alt text](https://github.com/jonathansavas/enpiction/blob/master/docs/images/encrypt_choose.gif) <br/><br/><br/>

#### Encrypting data in images with key

![alt text](https://github.com/jonathansavas/enpiction/blob/master/docs/images/encrypt_key.gif) <br/><br/><br/>

#### Choosing images and decrypting data

![alt text](https://github.com/jonathansavas/enpiction/blob/master/docs/images/decrypt.gif) <br/><br/><br/>

## Usage details

As previously mentioned, data is meant to be hidden in groups. Groups can be of size 1-5 images, encryption keys of size 1-16
characters, and data of size 1-128 characters. Keys can be reused: it is recommended to use the same key for all groups. The 
security here is meant to come from the user's knowledge of where the data is hidden and not from remembering many encryption keys.
When decrypting, users must choose the exact group of images that were encrypted (with the correct key, of course). For example,
a user encrypts data into a group of 3 images. When decrypting, if the user selects 2 of the 3 image, even with the correct key
the data will not be revealed. In addition, if the user selects the 3 correct images and also a 4th, the data will not be revealed.
This is to prevent someone who has stolen the key to choose every single image on the device to reveal the secret data.
