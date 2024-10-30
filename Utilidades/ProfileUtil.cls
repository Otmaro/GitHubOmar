public with sharing class ProfileUtil {

    private static Map<String, Profile> mProfilesById;
    private static Map<String, Profile> mProfilesByName;

    public static final String LOSAN_USER_PROFILE_NAME = 'Losan User';

    public static String getProfileIdByName(String name) {
        setProfileMaps();
        return mProfilesByName.get(name)?.Id;
    }

    public static String getProfileNameById(String profileId) {
        setProfileMaps();
        return mProfilesById.get(profileId)?.Name;
    }

    public static String getSysAdminProfileId() {
        return getProfileIdByName(System.Label.SystemAdministratorLabel);
    }

    private static void setProfileMaps() {
        if (mProfilesById == null || mProfilesByName == null) {
            mProfilesById = new Map<String, Profile>();
            mProfilesByName = new Map<String, Profile>();
            List<Profile> lProfiles = [SELECT Id, Name FROM Profile];
            for (Profile p : lProfiles) {
                mProfilesById.put(p.Id, p);
                mProfilesByName.put(p.Name, p);
            }
        }
    }

}