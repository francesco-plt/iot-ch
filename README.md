# IoT Challenges

## Structure of the repo

Each challenge folder has the following content:

* `challengeX.pdf`: description of the problem;
* `src`: code used to solve the challenge;
* `chX.md`: small project report;
* `assets`: folder containing `.png` files used in Markdown reports.

Plus other miscellaneous files used while completing the challenges.

## Compiling the reports as `.pdf`

Challenge reports are produced by exporting the `.md` with `pandoc`, for example:

```
$ pandoc -o ch1.pdf ch1.md
```
