# @summary Configure yum repos for a pakrat server
#          yumrepo baseurl will be constructed from parts as follows:
#          yumserver_url/os_info/reponame/snapshot
#
#          Defaults are specified for each of these parts
#          and any part can be overridden at the repo level
#          by specifying the key in it's hash data.
#
# @param default_snapshot,
#        String
#        default_snapshot (Pakrat-style snapshot ID, e.g., 2019-04-10-1554931501)

# @param default_yumserver_url
#        String
#        (e.g., http://lsst-repos01.ncsa.illinois.edu)
#
# @param default_os_info
#        String
#        should be gathered by Hiera data-in-module
#        will result in something like centos/$releasever/$basearch
#
# @param repos - Hash, with the following format:
#        Repo_Name: (used for yumrepo resource, corresponds to Yum repositoryid)
#            yumserver_url: (optional) override default_yumserver_url
#            snapshot:      (optional) override $default_snapshot
#            os_info:       (optional) override $os_info
#            reponame:      (optional) override Repo_Name
#            * <any valid attribute to pass to Puppet yumrepo resource>

class pakrat_client (
    String $default_snapshot,
    String $default_yumserver_url,
    String $default_os_info,
    Hash[ String[1], Hash ] $repos,

) {

    # Keys used for baseurl construction
    $baseurl_keys = [ 'yumserver_url', 'snapshot', 'os_info', 'reponame' ]

    $repos.each | String[1] $reponame, Hash $repodata| {

        if 'baseurl' in $repodata {
            # baseurl was given, nothing to do
            $custom = {}
        }
        else {

            # Baseurl wasn't given, so construct it from parts
            $defaults = {
                yumserver_url => $default_yumserver_url,
                os_info       => $default_os_info,
                reponame      => $reponame,
                snapshot      => $default_snapshot,
            }

            # Allow settings in repodata to override defaults
            $baseurl_data = $defaults + $repodata

            # Extract the values from baseurl_data in the order given by baseurl_keys
            $baseurl_parts = $baseurl_keys.reduce([]) |$memo,$key| {
                $memo + [ $baseurl_data[ $key ] ]
            }

            # now that parts are in the correct order, join them
            $constructed_baseurl = $baseurl_parts.join('/')
            $custom = { 'baseurl' => $constructed_baseurl }
        }

        # Remove non-yumrepo keys from config data
        # Add any values from custom
        $config = $repodata - $baseurl_keys + $custom

        # Declare the yumrepo resource
        yumrepo { $reponame:
            * => $config,
        }
    }

}
