# Build a Kernel

I read an article that was trying to convince folks that vendor kernels are
inherently insecure. That's because Linux vendor kernels are created by 
taking a snapshot of a specific Linux release and then backporting selected
fixes as changes occur in the upstream git tree. Using an up-to-date Linux
kernel release contains all the known fixes is the most secure option
available.

While this was a controversial topic, it got me thinking about Linux kernels.
A vendor kernel could be two (2) Major versions behind the upstream version. 
We can not reasonably expect the vendor to port ALL the security fixes back
two major levels. There must be some changes that are too large or require
the new major structure to properly implement the fix. Therefore the vendor
kernels are never going to contain all fixes, just the fixes that are notable.

As an Administrator I put time into mitigation of Common Vulnerabilities and
Exposures (CVE). If we build and use the latest stable version and spend time
working on compatibility or fixing instability.

I am sure I will live to regret this decision but here goes...

## Resources

* [The Linux Kernel Archives](https://kernel.org) - https://kernel.org
* [Build a Debian Kernel](https://wiki.debian.org/BuildADebianKernelPackage) - https://wiki.debian.org/BuildADebianKernelPackage
* [Enterprise Linux custom kernel](https://docs.rockylinux.org/guides/custom-linux-kernel/) - https://docs.rockylinux.org/guides/custom-linux-kernel/

---  

