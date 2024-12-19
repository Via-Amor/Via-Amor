//
//  SceneDelegate.swift
//  Amor
//
//  Created by 양승혜 on 10/23/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?
    var isUser = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)
        
        // 리프레스 토큰 만료 시 관찰할 옵저버 등록
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(isExpiredRefreshToken),
            name: .expired,
            object: nil
        )
        
        // 코디네이터 초기화면 설정
        let navigationController = UINavigationController()
        appCoordinator = AppCoordinator(navigationController: navigationController)
        
        isUser = UserDefaultsStorage.token.isEmpty
        
        if isUser {
            appCoordinator?.showUserFlow()
        } else {
            appCoordinator?.showMainFlow()
        }
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    @objc
    private func isExpiredRefreshToken() {
        UserDefaultsStorage.removeAll()
        
        // TODO: 추후 삭제 예정
        //UserDefaultsStorage.spaceId = "9dcff8fe-0d91-4381-8e61-3e94e3162e23"
        appCoordinator?.removeAllChild()
        appCoordinator?.showUserFlow()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}
