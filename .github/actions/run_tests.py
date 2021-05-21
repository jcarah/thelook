import looker_sdk
from looker_sdk import models
import configparser
import hashlib
import csv
import argparse
import sys
from pprint import pprint

config_file = "looker.ini"
sdk = looker_sdk.init31(config_file)

# Setup argparser
parser = argparse.ArgumentParser()
parser.add_argument(
    '--branch', 
    '-b', 
    type=str, 
    required=False, 
    help='Specify developer branch to checkout.'
)
parser.add_argument(
    '--project', 
    '-p', 
    type=str, 
    required="--branch in sys.argv", 
    help='Specify a LookML project.'
)
args = parser.parse_args()

def main():
    """Compare the output of content validator runs
    in production and development mode. Additional
    broken content in development mode will be
    outputted to a csv file.
    Use this script to test whether LookML changes
    will result in new broken content."""
    base_url = "https://profservices.dev.looker.com/"
    space_data = get_space_data()
    print("Checking for broken content in production.")
    broken_content_prod = parse_broken_content(
        base_url, get_broken_content(), space_data
    )
    enter_dev_mode()
    if args.branch:
        branch_name = args.branch
        lookml_project = args.project
        checkout_dev_branch(branch_name, lookml_project)
        sync_dev_branch_to_remote(lookml_project)
    print("Checking for broken content in dev branch.")
    broken_content_dev = parse_broken_content(
        base_url, get_broken_content(), space_data
    )
    new_broken_content = compare_broken_content(broken_content_prod, broken_content_dev)
    if len(new_broken_content) > 0:
        print("New broken content:")
        pprint(new_broken_content)
        raise Exception(""""
            Uh Oh! Looks like you broke some content. 
            Please fix and resubmit
        """)
    else:
        print("No new broken content in development branch.")

def get_base_url(config_file):
    """ Pull base url from looker.ini, remove port"""
    config = configparser.ConfigParser()
    config.read(config_file)
    full_base_url = config.get("Looker", "base_url")
    try:
        api_port = config.get("Looker","api_port")
    except:
        api_port = None
    if api_port:
        base_url = full_base_url
    else:
        try:
            base_url = full_base_url[:full_base_url.index(":19999")]
        except:
            base_url = full_base_url[:full_base_url.index(":443")]
    return base_url


def get_space_data():
    """Collect all space information"""
    space_data = sdk.all_spaces(fields="id, parent_id, name")
    return space_data


def get_broken_content():
    """Collect broken content"""
    broken_content = sdk.content_validation().content_with_errors
    return broken_content


def parse_broken_content(base_url, broken_content, space_data):
    """Parse and return relevant data from content validator"""
    output = []
    for item in broken_content:
        if item.dashboard:
            content_type = "dashboard"
        elif item.look:
            content_type = "look"
        else:
            content_type = "other"
        if content_type == "other":
            pass
        else:
            item_content_type = getattr(item, content_type)
            if item_content_type is None:
                pass
            id = item_content_type.id
            name = item_content_type.title
            space_id = item_content_type.space.id
            space_name = item_content_type.space.name
            errors = item.errors
            url = f"{base_url}/{content_type}s/{id}"
            space_url = "{}/spaces/{}".format(base_url, space_id)
            if content_type == "look":
                element = None
            else:
                dashboard_element = item.dashboard_element
                element = dashboard_element.title if dashboard_element else None
            # Lookup additional space information
            space = next(i for i in space_data if str(i.id) == str(space_id))
            parent_space_id = space.parent_id
            # Old version of API  has issue with None type for all_space() call
            if parent_space_id is None or parent_space_id == "None":
                parent_space_url = None
                parent_space_name = None
            else:
                parent_space_url = "{}/spaces/{}".format(base_url, parent_space_id)
                parent_space = next(
                    (i for i in space_data if str(i.id) == str(parent_space_id)), None
                )
                # Handling an edge case where space has no name. This can happen
                # when users are improperly generated with the API
                try:
                    parent_space_name = parent_space.name
                except AttributeError:
                    parent_space_name = None
            # Create a unique hash for each record. This is used to compare
            # results across content validator runs
            unique_id = hashlib.md5(
                "-".join(
                    [str(id), str(element), str(name), str(errors), str(space_id)]
                ).encode()
            ).hexdigest()
            data = {
                "unique_id": unique_id,
                "content_type": content_type,
                "name": name,
                "url": url,
                "dashboard_element": element,
                "space_name": space_name,
                "space_url": space_url,
                "parent_space_name": parent_space_name,
                "parent_space_url": parent_space_url,
                "errors": str(errors),
            }
            output.append(data)
    return output


def compare_broken_content(broken_content_prod, broken_content_dev):
    """Compare output between 2 content_validation runs"""
    unique_ids_prod = set([i["unique_id"] for i in broken_content_prod])
    unique_ids_dev = set([i["unique_id"] for i in broken_content_dev])
    new_broken_content_ids = unique_ids_dev.difference(unique_ids_prod)
    new_broken_content = []
    for item in broken_content_dev:
        if item["unique_id"] in new_broken_content_ids:
            new_broken_content.append(item)
    return new_broken_content

def enter_dev_mode():
    """Enter dev workspace"""
    sdk.update_session(models.WriteApiSession(workspace_id="dev"))

def checkout_dev_branch(branch_name, lookml_project):
    """Checkout a specific dev branch"""
    print(f"Checking out {branch_name}")
    branch = models.WriteGitBranch(name=branch_name)
    sdk.update_git_branch(project_id=lookml_project, body=branch)

def sync_dev_branch_to_remote(lookml_project):
    """Pull down changes from remote repo"""
    sdk.reset_project_to_remote(project_id=lookml_project)

main()
