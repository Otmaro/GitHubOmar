public with sharing class UserRoleUtil {

    private static Map<String, UserRole> mRolesById;
    private static Map<String, UserRole> mRolesByDevName;
    public static final String SALES_AGENT_ROLE_DEVNAME = 'Sales';
    public static final String PRODUCT_MANAGER_ROLE_DEVNAME = 'ProductManager';
    public static final String SALES_MANAGER_ROLE_DEVNAME = 'SalesManager';
    public static final String DIRECTOR_ROLE_DEVNAME = 'Director';

    public static String getRoleDevNameById(String roleId) {
        setRolesMaps();
        return mRolesById.get(roleId)?.DeveloperName;
    }

    public static String getRoleIdByDevName(String devName) {
        setRolesMaps();
        return mRolesByDevName.get(devName)?.Id;
    }

    public static Boolean isCurrentUserASalesAgent() {
        return getRoleDevNameById(UserInfo.getUserRoleId()) == SALES_AGENT_ROLE_DEVNAME;
    }

    private static void setRolesMaps() {
        if (mRolesById == null || mRolesByDevName == null) {
            mRolesById = new Map<String, UserRole>();
            mRolesByDevName = new Map<String, UserRole>();

            List<UserRole> lUserRoles = [SELECT Id, DeveloperName FROM UserRole];
            for (UserRole ur: lUserRoles) {
                mRolesById.put(ur.Id, ur);
                mRolesByDevName.put(ur.DeveloperName, ur);
            }
        }
    }

}