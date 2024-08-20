# 17. Edit `summernote-lite-v2.min.js` file guideline

Date: 2024-08-20

## Status

Accepted

## Context

- The logic of `summernote-lite-v2.min.js` is complicated to follow by all developers
- What is `minification`? Why do we need to `minify`? We can see more [here](https://www.cloudflare.com/learning/performance/why-minify-javascript-code/)

## Decision

Brief the steps when editing the `summernote-lite-v2.min.js` file to make it easier to track its changes during development:

- `summernote-lite-unminified.js` is the file `summernote-lite-v2.min.js` when it has not been `minified`. 
So when we want to change the code in `summernote-lite-v2.min.js`, 
we will modify the code in `summernote-lite-unminified.js` 
then `minified` it into a new temporary file and copy that new file back into `summernote-lite-v2.min.js`.

- The basic steps diagram is as follows:
    - Step 1: Edit `summernote-lite-unminified.js` file 
    - Step 2: Minify `summernote-lite-unminified.js` file to `summernote-lite-minified-temp.js` file 
    - Step 3: Copy content `summernote-lite-minified-temp.js` file to `summernote-lite-v2.min.js` file 
    - Step 4: Delete `summernote-lite-minified-temp. js` files

## Consequences

- Any logic changes to `summernote-lite-v2.min.js` must be updated in this ADR
