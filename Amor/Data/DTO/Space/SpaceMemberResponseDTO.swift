//
//  DMSpaceMembersResponseDTO.swift
//  Amor
//
//  Created by 김상규 on 11/3/24.
//

import Foundation

struct SpaceMemberResponseDTO: Decodable {
    let user_id: String
    let nickname: String
    let email: String
    let profileImage: String?
}

extension SpaceMemberResponseDTO {
    func toDomain() -> SpaceMember {
        return SpaceMember(
            user_id: user_id,
            nickname: nickname,
            email: email,
            profileImage: profileImage
        )
    }
}
